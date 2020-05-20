# == Schema Information
#
# Table name: review_sessions
#
#  id         :bigint           not null, primary key
#  series_id  :integer
#  released   :boolean          default(FALSE), not null
#  deadline   :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ReviewSession < ApplicationRecord
  belongs_to :series

  has_many :annotations, dependent: :nullify
  has_many :review_exercises, dependent: :destroy
  has_many :review_users, dependent: :destroy
  has_many :reviews, dependent: :destroy

  has_many :users, through: :review_users
  has_many :exercises, through: :review_exercises

  validates :deadline, presence: true

  before_save :manage_reviews
  after_save :manage_user_notifications
  before_destroy :destroy_notification

  def users=(new_users)
    removed = users - new_users
    review_users.where(user: removed).destroy_all
    super(new_users)
  end

  def exercises=(new_exercises)
    removed = exercises - new_exercises
    review_exercises.where(exercise: removed).destroy_all
    super(new_exercises)
  end

  def next_incomplete_review
    reviews.incomplete.order(id: :asc).first
  end

  def metadata
    {
      done: reviews.complete.count,
      total: reviews.count
    }
  end

  def review_sheet
    exercises = review_exercises.includes(:exercise).map(&:exercise)
    exercise_ids = exercises.pluck(:id)
    users = review_users.includes(:user).map(&:user)

    all_reviews = reviews.includes(review_exercise: [:exercise], review_user: [:user]).to_a
    revs = users.map do |user|
      [user.id, all_reviews.select { |rev| rev.review_user.user == user }.sort_by { |rev| exercise_ids.find_index rev.review_exercise.exercise.id }]
    end.to_h

    {
      exercises: exercises,
      reviews: revs
    }
  end

  private

  def manage_reviews
    existing = reviews.to_a
    review_users.to_a.each do |ru|
      review_exercises.to_a.each do |re|
        reviews.new(review_user: ru, review_exercise: re) if existing.select { |r| r.review_user == ru && r.review_exercise == re }.blank?
      end
    end
  end

  def manage_user_notifications
    Notification.where(notifiable: self)&.destroy_all
    return unless released

    users.find_each do |user|
      Notification.create(notifiable: self, user_id: user.id, message: 'review_sessions.overview.released')
    end
  end

  def destroy_notification
    Notification.where(notifiable: self)&.destroy_all
  end
end
