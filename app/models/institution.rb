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
  CACHE_EXPIRY_TIME = 5.minutes
  SIMILARITY_MATRIX_CACHE_STRING = '/Institutions/similarity_matrix'.freeze
  MOST_SIMILAR_CACHE_STRING = '/Institutions/most_similar'.freeze
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
  scope :order_by_similarity_to, lambda { |id, direction|
    joins("LEFT JOIN (values ('id', 'score'),#{Institution.most_similarity_matrix[id]
                                                          .map
                                                          .with_index { |s, i| "(#{i}, #{s})" }
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

  def self.most_similarity_matrix
    Rails.cache.fetch(SIMILARITY_MATRIX_CACHE_STRING, expires_in: CACHE_EXPIRY_TIME) do
      # create a matrix of all institutions and their similarity scores
      max_id = Institution.maximum(:id) + 1
      matrix = Array.new(max_id) { Array.new(max_id, 0) }

      # count the amount of users with the same email address
      sql = "
        SELECT count(u.email) AS count, u.institution_id, u2.institution_id AS other_institution_id
        FROM users u INNER JOIN users u2 ON u.email = u2.email
        WHERE u.institution_id != u2.institution_id AND u.institution_id IS NOT NULL AND u2.institution_id IS NOT NULL AND u.email IS NOT NULL
        GROUP BY u.institution_id, u2.institution_id
      "
      ActiveRecord::Base.connection.execute(sql).each do |row|
        matrix[row[1]][row[2]] += row[0].to_i
      end

      # count the amount of users with the same username
      sql = "
        SELECT count(u.username) AS count, u.institution_id, u2.institution_id AS other_institution_id
        FROM users u INNER JOIN users u2 ON u.username = u2.username
        WHERE u.institution_id != u2.institution_id AND u.institution_id IS NOT NULL AND u2.institution_id IS NOT NULL AND u.username IS NOT NULL
        GROUP BY u.institution_id, u2.institution_id
      "
      ActiveRecord::Base.connection.execute(sql).each do |row|
        matrix[row[1]][row[2]] += row[0].to_i
      end

      # lastly we look at the similarity in email address domains
      # This is a bit more complex
      # We try to find if a certain domain is used frequently by multiple institutions
      # We take the maximum of the domain overlap instead of the sum, because one domain with a lot of overlap is more important than multiple domains with a little overlap
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

      matrix
    end
  end

  def self.most_similar_institutions
    Rails.cache.fetch(MOST_SIMILAR_CACHE_STRING, expires_in: CACHE_EXPIRY_TIME) do
      institutions = Institution.all.index_by(&:id)
      Institution.most_similarity_matrix.map { |row| row.each_with_index.max }.map { |row| { id: row[1], name: institutions[row[1]]&.name, score: row[0] } }
    end
  end

  def most_similar_institution
    Institution.most_similar_institutions[id]
  end

  def similarity(other)
    Institution.most_similarity_matrix[id][other.id]
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
