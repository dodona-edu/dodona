# == Schema Information
#
# Table name: repositories
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  remote       :string(255)
#  path         :string(255)
#  judge_id     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  clone_status :integer          default("queued"), not null
#  featured     :boolean          default(FALSE)
#
require 'open3'
require 'pathname'

class Repository < ApplicationRecord
  include Gitable

  ACTIVITY_LOCATIONS = Rails.root.join('data/exercises').freeze
  PUBLIC_DIR = 'public'.freeze
  MEDIA_DIR = 'media'.freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :remote, presence: true, uniqueness: { case_sensitive: false }

  validate :repo_is_accessible, on: :create

  before_create :create_full_path
  after_create :clone_repo_delayed

  after_save :process_activities_email_errors_delayed, if: :saved_change_to_judge_id?

  belongs_to :judge
  has_many :activities, dependent: :restrict_with_error
  has_many :labels,
           -> { distinct },
           through: :activities,
           source: :labels
  has_many :programming_languages,
           -> { distinct },
           through: :activities,
           source: :programming_language
  has_many :judges,
           -> { distinct },
           through: :activities,
           source: :judge
  has_many :repository_admins, dependent: :restrict_with_error
  has_many :admins,
           through: :repository_admins,
           source: :user
  has_many :course_repositories, dependent: :restrict_with_error
  has_many :allowed_courses,
           through: :course_repositories,
           source: :course

  # TODO: Remove
  has_many :content_pages, dependent: :restrict_with_error
  has_many :exercises, dependent: :restrict_with_error

  scope :has_allowed_course, ->(course) { joins(:course_repositories).where(course_repositories: { course_id: course&.id }) }
  scope :has_admin, ->(user) { joins(:repository_admins).where(repository_admins: { user_id: user&.id }) }
  scope :owned_by_institution, ->(institution) { where(id: RepositoryAdmin.joins(:user).where(users: { institution_id: institution&.id }).where.not(users: { institution_id: nil }).group(:repository_id).select(:repository_id)) }
  scope :featured, -> { where(featured: true) }

  def full_path
    Pathname.new File.join(ACTIVITY_LOCATIONS, path)
  end

  def public_path
    full_path + PUBLIC_DIR
  end

  def public_files
    pathname_dir = Pathname.new public_path
    Dir[File.join(public_path, '**/*')] # uses entries in the locally stored Dodona copy of the repository
      .map { |f| Pathname.new f }
      .select { |path| path.file? && path.readable? } # skip directories such as ., icons/
      .map { |path| path.relative_path_from pathname_dir } # make them relative again to be able to create urls
  end

  def media_path
    full_path + MEDIA_DIR
  end

  def commit(msg)
    author = if Current.user&.full_name && Current.user&.email
               "#{Current.user.full_name} <#{Current.user.email}>"
             else
               'Dodona <dodona@ugent.be>'
             end
    _out, error, status = Open3.capture3('git', 'commit', "--author=\"#{author}\"", '-am', "#{msg}\n\nThis commit was created automatically by Dodona.", chdir: full_path.to_path)
    # rubocop:disable Style/SoleNestedConditional
    if Rails.env.production?
      _out, error, status = Open3.capture3('git push', chdir: full_path.to_path) if status.success?
    end
    # rubocop:enable Style/SoleNestedConditional
    [status.success?, error]
  end

  def first_admin
    repository_admins.first&.user
  end

  def activity_dirs
    activity_dirs_below(full_path)
  end

  def clone_repo
    super
    process_activities_email_errors if clone_complete?
  end

  def process_activities_email_errors_delayed(kwargs = {})
    delay(queue: 'git').process_activities_email_errors(kwargs)
  end

  def process_activities_email_errors(kwargs = {})
    recipient_is_invalid = kwargs.empty? || kwargs[:email]&.end_with?('@users.noreply.github.com')

    if recipient_is_invalid && admins.any?
      kwargs[:user] = admins.first
    elsif recipient_is_invalid
      kwargs[:email] = Rails.application.config.dodona_email
    end

    process_activities
  rescue AggregatedConfigErrors => e
    ErrorMailer.json_error(e, **kwargs).deliver
  rescue DodonaGitError => e
    ErrorMailer.git_error(e, **kwargs).deliver
  end

  def process_activities
    dirs = activity_dirs
    errors = []

    activity_dirs_and_configs = dirs.map do |d|
      Pathname.new('./').join(activity_relative_path(d)).parent.descend.each do |p|
        read_config_file(full_path.join(p, Activity::DIRCONFIG_FILE))
      end
      [d, read_config_file(Activity.config_file(d))]
    rescue ConfigParseError => e
      errors.push e
      nil
    end.compact

    existing_activities = activity_dirs_and_configs
                          .reject { |_, c| c['internals'].nil? || c['internals']['token'].nil? }
                          .map { |d, c| [d, Activity.find_by(repository_token: c['internals']['token'], repository_id: id)] }
                          # rubocop:disable Style/CollectionCompact
                          # This is a false positive for Hash#compact, where this is Array#compact
                          .reject { |_, e| e.nil? }
                          # rubocop:enable Style/CollectionCompact
                          .group_by { |_, e| e }
                          .transform_values { |l| l.pluck(0) }
    handled_directories = []
    handled_activity_ids = []
    new_activities = []

    existing_activities.each do |act, directories|
      orig_path = directories.select { |dir| dir == act.full_path }.first || directories.first
      act.path = activity_relative_path orig_path

      # Converting an exercise to a content page causes issues if
      # submissions exist for that exercise.
      # Create a new, removed exercise to attach the submissions to.
      if act.becomes_content_page? && act.submissions.exists?
        new_act = act.dup
        new_act.attributes = { path: nil, status: :removed, repository_token: nil }
        new_act.save

        Submission.where(exercise_id: act.id).update(exercise_id: new_act.id)
      end

      update_activity act
      handled_activity_ids.push act.id
      handled_directories.push orig_path
      directories.reject { |dir| dir == orig_path }.each do |dir|
        new_act = Activity.new(path: activity_relative_path(dir), repository_id: id)
        new_activities.push new_act
        update_activity new_act
        handled_activity_ids.push new_act.id
        handled_directories.push dir
      end
    end

    repository_activities = Activity.where(repository_id: id)
    repository_activities.reject { |a| handled_activity_ids.include? a.id }.each do |act|
      if dirs.include?(act.full_path) && handled_directories.exclude?(act.full_path)
        handled_directories.push act.full_path
        if activity_dirs_and_configs.select { |d, _| d == act.full_path }.first.nil?
          act.update(status: :not_valid)
        else
          update_activity act
          act.update_config
        end
      else
        act.update(status: :removed, path: nil)
      end
    end

    # rubocop:disable Style/HashExcept
    # activity_dirs_and_configs is not a hash
    activity_dirs_and_configs.reject { |d, _| handled_directories.include? d }.each do |dir, c|
      token = c['internals'] && c['internals']['token']
      if token.is_a?(String) && token.length == 64 && Activity.find_by(repository_token: token).nil?
        act = Activity.new(path: activity_relative_path(dir), repository_id: id, repository_token: token)
      else
        act = Activity.new(path: activity_relative_path(dir), repository_id: id)
        new_activities.push act
      end
      update_activity act
    end
    # rubocop:enable Style/HashExcept

    new_activities.each do |act|
      c = act.config
      c['internals'] = {}
      c['internals']['token'] = act.repository_token
      c['internals']['_info'] = 'These fields are used for internal bookkeeping in Dodona, please do not change them.'
      act.config_file.write(JSON.pretty_generate(c))
    end

    unless new_activities.empty?
      status, err = commit 'stored tokens in new activities'
      # handle errors when commit fails
      raise DodonaGitError.new(self, err) unless status
    end

    raise AggregatedConfigErrors.new(self, errors) if errors.any?
  end

  def update_activity(act)
    config = act.merged_config
    type = Activity.parse_type config['type']

    if type == ContentPage.name
      act = act.becomes(ContentPage)
    elsif type == Exercise.name
      act = act.becomes(Exercise)
    end

    labels = config['labels']&.map do |name|
      Label.find_by(name: name) || Label.create(name: name)
    end || []

    act.access = Activity.convert_visibility_to_access(config['visibility']) if config['visibility']
    act.access = config['access'] if config['access']
    act.access ||= :private
    act.description_format = Activity.determine_format(act.full_path)
    act.name_en = config['description']&.fetch('names', nil)&.fetch('en', nil)
    act.name_nl = config['description']&.fetch('names', nil)&.fetch('nl', nil)
    languages = act.description_languages
    act.description_nl_present = languages.include? 'nl'
    act.description_en_present = languages.include? 'en'
    act.labels = labels
    act.status = :ok
    act.type = type

    if act.exercise?
      j = nil
      j = Judge.find_by(name: config['evaluation']['handler']) if config['evaluation']
      programming_language_name = config['programming_language']
      programming_language = nil
      if programming_language_name
        programming_language = ProgrammingLanguage.find_by(name: programming_language_name)
        programming_language ||= ProgrammingLanguage.create(name: programming_language_name)
      end

      act.judge = j || judge
      act.programming_language = programming_language
    end

    act.save
  end

  def github_url(path = nil, mode: nil)
    return unless github_remote?

    mode ||= 'tree'

    url = remote.sub(':', '/').sub(/^git@/, 'https://').sub(/\.git$/, '')
    url += "/#{mode}/master/#{path&.to_s}"
    url
  end

  def read_config_file(file)
    file = full_path + file if file.relative?
    rel_path = file.relative_path_from(full_path)
    if file.file?
      result = JSON.parse file.read.force_encoding('UTF-8').scrub
      raise ConfigParseError.new(self, rel_path, 'file contents are not a JSON object', result.to_json) unless result.is_a?(Hash)

      result
    end
  rescue JSON::ParserError => e
    # ew.
    groups = /\d*:?(?<error_type>.*) at '(?<json>.*)'/m.match(e.to_s)
    error_type = groups[:error_type]
    json = groups[:json]
    raise ConfigParseError.new(self, rel_path, error_type, json)
  end

  private

  def activity_dirs_below(directory)
    if activity_directory?(directory)
      [directory.cleanpath]
    else
      directory.entries
               .reject { |entry| entry.basename.to_path.start_with?('.') }
               .map { |entry| entry.expand_path(directory) }
               .select(&:directory?)
               .flat_map { |entry| activity_dirs_below(entry) }
    end
  end

  def activity_directory?(file)
    Activity.config_file? file
  end

  def activity_relative_path(path)
    path.cleanpath.relative_path_from full_path
  end
end
