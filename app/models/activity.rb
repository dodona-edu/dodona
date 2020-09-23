# == Schema Information
#
# Table name: activities
#
#  id                      :integer          not null, primary key
#  name_nl                 :string(255)
#  name_en                 :string(255)
#  description_nl_present  :boolean
#  description_en_present  :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  path                    :string(255)
#  description_format      :string(255)
#  repository_id           :integer
#  judge_id                :integer
#  status                  :integer          default("ok")
#  access                  :integer          default("public"), not null
#  programming_language_id :bigint
#  search                  :string(4096)
#  access_token            :string(16)       not null
#  repository_token        :string(64)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#  type                    :string(255)      default("Exercise"), not null
#

require 'pathname'
require 'action_view'

class Activity < ApplicationRecord
  include ActionView::Helpers::DateHelper
  include Filterable
  include StringHelper
  include Cacheable
  include Tokenable

  USERS_READ_CACHE_STRING = '/course/%<course_id>s/activity/%<id>s/users_read'.freeze
  CONFIG_FILE = 'config.json'.freeze
  DIRCONFIG_FILE = 'dirconfig.json'.freeze
  DESCRIPTION_DIR = 'description'.freeze
  MEDIA_DIR = File.join(DESCRIPTION_DIR, 'media').freeze

  # We need to prefix, otherwise Rails can't generate the public? method
  enum access: { public: 0, private: 1 }, _prefix: true
  enum status: { ok: 0, not_valid: 1, removed: 2 }

  belongs_to :repository
  belongs_to :judge, optional: true
  belongs_to :programming_language, optional: true
  has_many :activity_read_states, dependent: :destroy
  has_many :activity_statuses, dependent: :destroy
  has_many :series_memberships, dependent: :restrict_with_error
  has_many :series, through: :series_memberships
  has_many :courses, -> { distinct }, through: :series
  has_many :activity_labels, dependent: :destroy
  has_many :labels, through: :activity_labels

  validates :path, uniqueness: { scope: :repository_id, case_sensitive: false }, allow_nil: true

  token_generator :repository_token, length: 64
  token_generator :access_token

  before_save :check_validity
  before_save :generate_access_token, if: :access_changed?
  before_create :generate_id
  before_create :generate_repository_token,
                if: ->(ex) { ex.repository_token.nil? }
  before_create :generate_access_token
  before_update :update_config

  scope :content_pages, -> { where(type: ContentPage.name) }
  scope :exercises, -> { where(type: Exercise.name) }

  scope :in_repository, ->(repository) { where repository: repository }

  scope :by_name, ->(name) { where('name_nl LIKE ? OR name_en LIKE ? OR path LIKE ?', "%#{name}%", "%#{name}%", "%#{name}%") }
  scope :by_status, ->(status) { where(status: status.in?(statuses) ? status : -1) }
  scope :by_access, ->(access) { where(access: access.in?(accesses) ? access : -1) }
  scope :by_labels, ->(labels) { includes(:labels).where(labels: { name: labels }).group(:id).having('COUNT(DISTINCT(activity_labels.label_id)) = ?', labels.uniq.length) }
  scope :by_programming_language, ->(programming_language) { includes(:programming_language).where(programming_languages: { name: programming_language }) }
  scope :by_type, ->(type) { where(type: type) }
  scope :by_judge, ->(judge) { where(judge_id: judge) }
  scope :by_description_languages, lambda { |languages|
    by_language = all # allow chaining of scopes
    by_language = by_language.where(description_en_present: true) if languages.include? 'en'
    by_language = by_language.where(description_nl_present: true) if languages.include? 'nl'
    by_language
  }

  def content_page?
    false
  end

  def exercise?
    false
  end

  def full_path
    return Pathname.new '' unless path

    Pathname.new File.join(repository.full_path, path)
  end

  def media_path
    full_path + MEDIA_DIR
  end

  def config_file
    full_path + CONFIG_FILE
  end

  def name
    first_string_present send('name_' + I18n.locale.to_s),
                         name_nl,
                         name_en,
                         path&.split('/')&.last
  end

  def description_languages
    languages = []
    languages << 'nl' if description_file('nl').exist?
    languages << 'en' if description_file('en').exist?
    languages
  end

  def description_file(lang)
    full_path + DESCRIPTION_DIR + "description.#{lang}.#{description_format}"
  end

  def description_localized(lang = I18n.locale.to_s)
    file = description_file(lang)
    file.read if file.exist?
  end

  def description_nl
    description_localized('nl')
  end

  def description_en
    description_localized('en')
  end

  def description
    (description_localized || description_nl || description_en || '').force_encoding('UTF-8').scrub
  end

  def about_by_precedence(lang = I18n.locale.to_s)
    return unless full_path.exist?

    files = full_path
            .children
            .filter { |path| path.file? && path.readable? }
            .index_by { |path| path.basename.to_s.downcase }

    first_matching = [
      "readme.#{lang}.md",
      "about.#{lang}.md",
      'readme.md',
      'readme',
      'readme.nl.md',
      'readme.en.md',
      'about.nl.md',
      'about.en.md'
    ].find { |fname| files.key?(fname) }

    files[first_matching]&.read
  end

  def about
    (about_by_precedence || '').force_encoding('UTF-8').scrub
  end

  def github_url
    repository.github_url(path)
  end

  def config
    repository.read_config_file(config_file)
  end

  def merged_dirconfig
    Pathname.new('./' + path).parent.descend # all parent directories
            .map { |dir| read_dirconfig dir } # try reading their dirconfigs
            .compact # remove nil entries
            .reduce { |h1, h2| deep_merge_configs h1, h2 } # reduce into single hash
            .yield_self { |dirconfig| lowercase_labels(dirconfig) || {} } # return empty hash if dirconfig is nil
  end

  def merged_dirconfig_locations
    Pathname.new('./' + path).parent.descend # all parent directories
            .map { |dir| read_dirconfig_locations dir } # try reading their dirconfigs
            .compact # remove nil entries
            .reduce { |h1, h2| deep_merge_configs h1, h2 } # reduce into single hash
            .yield_self { |dirconfig| unique_labels(dirconfig) || {} } # return empty hash if dirconfig is nil
  end

  def merged_config
    lowercase_labels deep_merge_configs(merged_dirconfig, config)
  end

  def merged_config_locations
    unique_labels deep_merge_configs(merged_dirconfig_locations, config_locations)
  end

  def config_file?
    Activity.config_file? full_path
  end

  def self.config_file?(directory)
    (directory + CONFIG_FILE).file?
  end

  def self.config_file(directory)
    directory + CONFIG_FILE
  end

  def self.dirconfig_file?(file)
    file.basename.to_s == DIRCONFIG_FILE
  end

  def store_config(new_config, message = nil)
    return if new_config == config

    message ||= "updated config for #{name}"
    config_file.write(JSON.pretty_generate(new_config))
    success, error = repository.commit message

    return if success || error.empty?

    errors.add(:base, "committing changes failed: #{error}")
    throw :abort
  end

  def update_config
    return unless ok?

    labels_to_write = labels.map(&:name) - (merged_dirconfig['labels'] || [])

    c = config
    c.delete('visibility')
    c['access'] = access if defined?(access) && access != merged_config['access']
    c['description']['names']['nl'] = name_nl if name_nl.present? || c['description']['names']['nl'].present?
    c['description']['names']['en'] = name_en if name_en.present? || c['description']['names']['en'].present?
    c['internals'] = {}
    c['internals']['token'] = repository_token
    c['internals']['_info'] = 'These fields are used for internal bookkeeping in Dodona, please do not change them.'
    c['labels'] = labels_to_write if (labels_to_write & (merged_config['labels'] || [])) != labels_to_write || labels_to_write == []
    store_config c
  end

  def usable_by?(course)
    access_public? || course.usable_repositories.pluck(:id).include?(repository.id)
  end

  def accessible?(user, course)
    if course.present?
      if user&.course_admin? course
        return false unless course.activities.pluck(:id).include? id
      else
        return false unless course.visible_activities.pluck(:id).include? id
      end
      return true if user&.repository_admin? repository
      return false unless access_public? \
          || repository.allowed_courses.pluck(:id).include?(course&.id)
      return true if user&.member_of? course
      return false if course.moderated && access_private?

      course.open_for_all? || (course.open_for_institution? && course.institution == user&.institution)
    else
      return true if user&.repository_admin? repository

      access_public?
    end
  end

  def read_state_for(user, course = nil)
    s = activity_read_states.of_user(user)
    s = s.in_course(course) if course
    s.first
  end

  def activity_statuses_for(user, course)
    nil_status = [activity_status_for(user, nil)]
    return nil_status if course.nil?

    nil_status + series_memberships.joins(:series).where('course_id = ?', course.id).map do |series_membership|
      activity_status_for(user, series_membership.series)
    end
  end

  def accepted_for?(user, series = nil)
    activity_status_for(user, series).accepted?
  end

  def accepted_before_deadline_for?(user, series = nil)
    activity_status_for(user, series).accepted_before_deadline?
  end

  def solved_for?(user, series = nil)
    activity_status_for(user, series).solved?
  end

  def wrong_for?(user, series = nil)
    activity_status_for(user, series).wrong?
  end

  def started_for?(user, series = nil)
    activity_status_for(user, series).started?
  end

  def users_read(options)
    states = activity_read_states
    states = states.in_course(options[:course]) if options[:course].present?
    states.distinct.count(:user_id)
  end

  invalidateable_instance_cacheable(:users_read,
                                    ->(this, options) { format(USERS_READ_CACHE_STRING, course_id: options[:course].present? ? options[:course].id.to_s : 'global', id: this.id.to_s) })

  def check_validity
    return unless ok?

    self.status = if !(name_nl || name_en)
                    :not_valid
                  elsif !(description_nl || description_en)
                    :not_valid
                  else
                    :ok
                  end
  end

  def self.convert_visibility_to_access(visibility)
    return 'public' if visibility == 'visible'
    return 'public' if visibility == 'open'
    return 'private' if visibility == 'invisible'
    return 'private' if visibility == 'hidden'
    return 'private' if visibility == 'closed'

    visibility
  end

  def self.determine_format(full_exercise_path)
    if !Dir.glob(full_exercise_path + DESCRIPTION_DIR + 'description.*.html').empty?
      'html'
    else
      'md'
    end
  end

  def self.move_relations(from, to)
    from.series_memberships.each { |sm| sm.update(activity: to) unless SeriesMembership.find_by(activity: to, series: sm.series) }
  end

  def safe_destroy
    return unless removed?
    return if series_memberships.any?

    destroy
  end

  def set_search
    self.search = "#{Activity.human_enum_name(:status, status, locale: :nl)} #{Activity.human_enum_name(:status, status, locale: :en)} #{Activity.human_enum_name(:access, access, locale: :en)} #{Activity.human_enum_name(:access, access, locale: :nl)} #{name_nl} #{name_en} #{path}"
  end

  def self.parse_type(type)
    return Exercise.name unless type
    return type if types.include?(type)
    return ContentPage.name if type.downcase == ContentPage.type
    return Exercise.name if type.downcase == Exercise.type

    Exercise.name
  end

  class << self
    def types
      %w[ContentPage Exercise]
    end
  end

  private

  def activity_status_for(user, series = nil)
    Current.status_store ||= {}
    Current.status_store[[user.id, series&.id, id]] ||= activity_status_for!(user, series)
  end

  def activity_status_for!(user, series = nil)
    first_try = true
    begin
      ActivityStatus.find_or_create_by(activity: self, series: series, user: user)
    rescue StandardError
      # https://github.com/dodona-edu/dodona/issues/1877
      raise unless first_try

      first_try = false
      retry
    end
  end

  # takes a relative path
  def read_dirconfig(subdir)
    repository.read_config_file(subdir + DIRCONFIG_FILE)
  end

  def read_config_locations(location)
    repository.read_config_file(location)
        &.deep_transform_values! { location }
  end

  def config_locations
    read_config_locations config_file
  end

  def read_dirconfig_locations(subdir)
    read_config_locations(subdir + DIRCONFIG_FILE)
  end

  def generate_id
    begin
      new = SecureRandom.random_number(2_147_483_646)
    end until Activity.find_by(id: new).nil?
    self.id = new
  end

  def deep_merge_configs(parent_conf, child_conf)
    parent_conf.deep_merge(child_conf) do |k, v1, v2|
      if k == 'labels'
        (v1 + v2)
      else
        v2
      end
    end
  end

  def lowercase_labels(hash)
    return unless hash

    hash['labels'] = hash['labels'].map(&:downcase).uniq if hash.key? 'labels'
    hash
  end

  def unique_labels(hash)
    return unless hash

    hash['labels'] = hash['labels'].uniq if hash.key? 'labels'
    hash
  end
end
