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
  IGNORED_DOMAINS_FOR_SIMILARITY = %w[gmail.com hotmail.com outlook.com yahoo.com live.com msn.com aol.com icloud.com telenet.be gmail.be live.be outlook.be hotmail.be].freeze
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

  scope :order_by_name, ->(direction) { reorder generated_name: :desc, name: direction }
  scope :order_by_short_name, ->(direction) { reorder short_name: direction }
  scope :order_by_courses, ->(direction) { joins("LEFT JOIN (#{Course.group(:institution_id).select(:institution_id, 'COUNT(id) AS count').to_sql}) courses on courses.institution_id = institutions.id").reorder("courses.count #{direction}") }
  scope :order_by_users, ->(direction) { joins("LEFT JOIN (#{User.group(:institution_id).select(:institution_id, 'COUNT(id) AS count').to_sql}) users on users.institution_id = institutions.id").reorder("users.count #{direction}") }
  scope :order_by_most_similar, lambda { |direction|
    reorder Arel.sql("FIELD(id, #{Institution.most_similar_institutions
                                               .map.with_index { |ins, i| [ins[:score], i] }.sort.pluck(1)
                                               .join(', ')})") => direction
  }
  scope :order_by_similarity_to, lambda { |id, direction|
    reorder Arel.sql("FIELD(id, #{Institution.similarity_matrix[id]
                                             .map.with_index { |s, i| [s, i] }.sort.pluck(1)
                                             .join(', ')})") => direction
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

  def self.similarity_matrix
    Rails.cache.fetch(SIMILARITY_MATRIX_CACHE_STRING, expires_in: CACHE_EXPIRY_TIME) do
      # create a matrix of all institutions and their similarity scores
      max_id = Institution.maximum(:id) + 1
      matrix = Array.new(max_id) { Array.new(max_id, 0) }

      # Get all usernames, emails and email domains, with their institution id
      usernames = User.select(:institution_id, :username).where('username IS NOT NULL and institution_id IS NOT NULL')
      emails = User.select(:institution_id, :email).where('email IS NOT NULL and institution_id IS NOT NULL')
      # Domains are already grouped and counted per unique domain for each institution
      # We also filter out common domains and avoid domains that appear only once in an institution
      domains = emails.map { |u| [u.email.split('@').last, u.institution_id] }
                      .tally.map { |k, v| { domain: k[0], institution_id: k[1], count: v } }
                      .filter { |u| IGNORED_DOMAINS_FOR_SIMILARITY.exclude?(u[:domain]) && u[:count] > 1 }

      # we group by domain to get all institutions with the same domain, we update the similarity matrix for all pairs of institutions
      domains.group_by { |u| u[:domain] }.each do |_, institution|
        institution.combination(2).each do |i1, i2|
          matrix[i1[:institution_id]][i2[:institution_id]] = [matrix[i1[:institution_id]][i2[:institution_id]], [i1[:count], i2[:count]].min].max
          matrix[i2[:institution_id]][i1[:institution_id]] = matrix[i1[:institution_id]][i2[:institution_id]]
        end
      end

      emails.group_by(&:email).each do |_, users|
        users.combination(2).each do |u1, u2|
          matrix[u1.institution_id][u2.institution_id] += 1
          matrix[u2.institution_id][u1.institution_id] += 1
        end
      end

      usernames.each { |u| u.username.downcase! }.group_by(&:username).each do |_, users|
        users.combination(2).each do |u1, u2|
          matrix[u1.institution_id][u2.institution_id] += 1
          matrix[u2.institution_id][u1.institution_id] += 1
        end
      end
      matrix
    end
  end

  def self.most_similar_institutions
    Rails.cache.fetch(MOST_SIMILAR_CACHE_STRING, expires_in: CACHE_EXPIRY_TIME) do
      institutions = Institution.all.index_by(&:id)
      Institution.similarity_matrix.map { |row| row.each_with_index.max }.map { |row| { id: row[1], name: institutions[row[1]]&.name, score: row[0] } }
    end
  end

  def most_similar_institution
    Institution.most_similar_institutions[id]
  end

  def similarity(other)
    Institution.similarity_matrix[id][other.id]
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
