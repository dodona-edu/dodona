# == Schema Information
#
# Table name: institutions
#
#  id             :bigint           not null, primary key
#  name           :string(255)
#  short_name     :string(255)
#  logo           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  generated_name :boolean          default(TRUE), not null
#  category       :integer          default("secondary"), not null
#

class Institution < ApplicationRecord
  include Gem::Text
  CACHE_EXPIRY_TIME = 1.day
  SIMILARITY_CACHE_STRING = '/Institutions/similarity_matrix'.freeze
  NEW_INSTITUTION_NAME = 'n/a'.freeze

  enum category: { secondary: 0, higher: 1, other: 2 }

  has_many :users, dependent: :restrict_with_error
  has_many :providers, inverse_of: :institution, dependent: :restrict_with_error
  has_many :courses, dependent: :restrict_with_error

  validates :logo, :short_name, presence: true
  validates_associated :providers

  accepts_nested_attributes_for :providers

  scope :of_course_by_members, ->(course) { joins(users: :courses).where(courses: { id: course.id }).distinct }
  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%").or(where('short_name LIKE ?', "%#{name}%")) }

  before_update :unmark_generated, if: :will_save_change_to_name?

  def name
    return self[:name] unless Current.demo_mode

    Faker::Config.random = Random.new(id + Date.today.yday)
    Faker::University.name
  end

  def preferred_provider
    providers.find_by(mode: :prefer)
  end

  def uses_lti?
    providers.any? { |provider| provider.type == Provider::Lti.name }
  end

  def uses_oidc?
    providers.any? { |provider| provider.type == Provider::Oidc.name }
  end

  def uses_smartschool?
    providers.any? { |provider| provider.type == Provider::Smartschool.name }
  end

  def unmark_generated
    self.generated_name = false
  end

  def self.similarity_matrix
    # create a matrix of all institutions and their similarity scores
    Rails.cache.fetch(SIMILARITY_CACHE_STRING, expires_in: CACHE_EXPIRY_TIME) do
      max_id = Institution.maximum(:id) + 1
      matrix = Array.new(max_id) { Array.new(max_id, 0) }

      Institution.find_each do |i|
        Institution.where('id > ?', i.id).find_each do |j|
          matrix[i.id][j.id] = i.similarity_score(j)[0]
          matrix[j.id][i.id] = matrix[i.id][j.id]
        end
      end
      matrix
    end
  end

  def self.sorted_most_similar_institutions
    Institution.all
               .map { |i| [i, i.most_similar_institution] }
               .map do |a|
                 [
                   Institution.similarity_matrix[a[0].id][a[1].id],
                   a[0].name,
                   a[0].id,
                   a[1].name,
                   a[1].id,
                   a[0].similarity_score(a[1])
                 ]
               end
               .sort
  end

  def most_similar_institution
    Institution.find(Institution.similarity_matrix[id].each_with_index.max[1])
  end

  def similarity_score(other)
    return 0 if other.nil?

    # increase score for similar names
    name_similarity = (1 - (levenshtein_distance(name, other.name)/[name.length, other.name.length].max.to_f)) * 2
    short_name_similarity = (1 - (levenshtein_distance(short_name, other.short_name)/[short_name.length, other.short_name.length].max.to_f)) * 2
    # increase score if users have the same email address
    email_similarity = users.where.not(email: nil)
                  .where(email: User.where(institution: other).where.not(email: nil).pluck(:email))
                  .count
    # increase score if users have the same username
    username_similarity = users.where.not(username: nil)
                  .where(username: User.where(institution: other).where.not(username: nil).pluck(:username))
                  .count
    # increase score if users have the same email domain
    domain_similarity = 0
    User.where(institution: other).where.not(email: nil)
        .pluck(:email)
        .map { |e| e.split('@').last }
        .filter { |e| %w[gmail.com hotmail.com outlook.com yahoo.com live.com msn.com aol.com icloud.com].exclude?(e) }
        .group_by { |e| e }.map { |k, v| [k, v.length] }.each do |domain, count|
      # we want to count the number of users with the same domain
      # which is the minimum of the number of users with that domain in each institution
      domain_similarity += [count, users.where.not(email: nil).where('email LIKE ?', "%#{domain}").count].min
    end
    score = name_similarity + short_name_similarity + email_similarity + username_similarity + domain_similarity
    [score.round, name_similarity, short_name_similarity, email_similarity, username_similarity, domain_similarity]
  end

  def merge_into(other)
    errors.add(:merge, "has overlapping usernames. Run `bin/rake merge_institutions[#{id},#{other.id}]` on the server to solve this using an interactive script.") if other.users.exists?(username: users.pluck(:username))
    errors.add(:merge, 'has link provider') if providers.any?(&:link?)
    return false if errors.any?

    providers.each do |p|
      if p.prefer?
        p.update(institution: other, mode: :secondary)
      else # secondary or redirect
        p.update(institution: other)
      end
    end
    courses.each { |c| c.update(institution: other) }
    users.each { |u| u.update(institution: other) }
    reload
    destroy
  end
end
