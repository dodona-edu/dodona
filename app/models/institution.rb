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

include Gem::Text
class Institution < ApplicationRecord
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

  scope :order_by_name, ->(direction) { reorder generated_name: direction, name: direction }
  scope :order_by_short_name, ->(direction) { reorder short_name: direction }
  scope :order_by_courses, ->(direction) { joins("LEFT JOIN (#{Course.group(:institution_id).select(:institution_id, 'COUNT(id) AS count').to_sql}) courses on courses.institution_id = institutions.id").reorder("courses.count #{direction}") }
  scope :order_by_users, ->(direction) { joins("LEFT JOIN (#{User.group(:institution_id).select(:institution_id, 'COUNT(id) AS count').to_sql}) users on users.institution_id = institutions.id").reorder("users.count #{direction}") }
  scope :order_by_most_similar, lambda { |direction|
    joins("LEFT JOIN (values ('id', 'score'),#{Institution.most_similar_institutions
                     .map
                     .with_index { |ins, i| "(#{i}, #{ins[:score]})" }
                     .join(', ')}) similarity ON similarity.id = institutions.id")
      .reorder Arel.sql("cast(similarity.score AS INT) #{direction}")
  }

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

  def self.most_similar_institution_ids
    Rails.cache.fetch(SIMILARITY_CACHE_STRING, expires_in: CACHE_EXPIRY_TIME) do
      # create a matrix of all institutions and their similarity scores
      max_id = Institution.maximum(:id) + 1
      matrix = Array.new(max_id) { Array.new(max_id, 0) }

      sql = "
        SELECT count(u.email) AS count, u.institution_id, u2.institution_id AS other_institution_id
        FROM users u INNER JOIN users u2 ON u.email = u2.email
        WHERE u.institution_id != u2.institution_id AND u.institution_id IS NOT NULL AND u2.institution_id IS NOT NULL AND u.email IS NOT NULL
        GROUP BY u.institution_id, u2.institution_id
      "
      ActiveRecord::Base.connection.execute(sql).each do |row|
        matrix[row[1]][row[2]] += row[0].to_i
      end

      sql = "
        SELECT count(u.username) AS count, u.institution_id, u2.institution_id AS other_institution_id
        FROM users u INNER JOIN users u2 ON u.username = u2.username
        WHERE u.institution_id != u2.institution_id AND u.institution_id IS NOT NULL AND u2.institution_id IS NOT NULL AND u.username IS NOT NULL
        GROUP BY u.institution_id, u2.institution_id
      "
      ActiveRecord::Base.connection.execute(sql).each do |row|
        matrix[row[1]][row[2]] += row[0].to_i
      end

      sql = "
        SELECT max(least(u.count, u2.count)) AS count, u.institution_id, u2.institution_id AS other_institution_id
        FROM (SELECT SUBSTR(email, INSTR(email, '@') + 1) AS domain,count(*) as count, institution_id FROM users WHERE email IS NOT NULL GROUP BY institution_id, domain) u
        INNER JOIN (SELECT SUBSTR(email, INSTR(email, '@') + 1) AS domain,count(*) as count, institution_id FROM users WHERE email IS NOT NULL GROUP BY institution_id, domain) u2 ON  u.domain = u2.domain
        WHERE u.institution_id != u2.institution_id AND u.institution_id IS NOT NULL AND u2.institution_id IS NOT NULL AND u.domain != ''
        AND u.domain NOT IN ('gmail.com', 'hotmail.com', 'outlook.com', 'yahoo.com', 'live.com', 'msn.com', 'aol.com', 'icloud.com', 'telenet.be', 'gmail.be', 'live.be', 'outlook.be', 'hotmail.be')
        GROUP BY u.institution_id, u2.institution_id
      "
      ActiveRecord::Base.connection.execute(sql).each do |row|
        matrix[row[1]][row[2]] += row[0].to_i
      end

      matrix.map { |row| row.each_with_index.max }.map { |row| { id: row[1], score: row[0] } }
    end
  end

  def self.most_similar_institutions
    institutions = Institution.all.index_by(&:id)
    most_similar_institution_ids.map { |row| { id: row[:id], institution: institutions[row[:id]], score: row[:score] } }
  end

  def most_similar_institution
    Institution.most_similar_institutions[id]
  end

  def similarity(other)
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
    max_domain_similarity = 0
    User.where(institution: other).where.not(email: nil)
        .pluck(:email)
        .map { |e| e.split('@').last }
        .filter { |e| %w[gmail.com hotmail.com outlook.com yahoo.com live.com msn.com aol.com icloud.com telenet.be live.be outlook.be hotmail.be].exclude?(e) }
        .group_by { |e| e }.map { |k, v| [k, v.length] }.each do |domain, count|
      # we want to count the number of users with the same domain
      # which is the minimum of the number of users with that domain in each institution
      domain_similarity = [count, users.where.not(email: nil).where('email LIKE ?', "%#{domain}").count].min
      max_domain_similarity = [max_domain_similarity, domain_similarity].max
    end
    score = name_similarity + short_name_similarity + email_similarity + username_similarity + max_domain_similarity
    {
      total: score.round,
      name: name_similarity,
      short_name: short_name_similarity,
      email: email_similarity,
      username: username_similarity,
      domain: max_domain_similarity
    }
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
