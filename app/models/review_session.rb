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

  def review_sheet
    exercises = review_exercises.includes(:exercise).map(&:exercise)
    exercise_ids = exercises.pluck(:id)
    users = review_users.includes(:user)

    revs = users.map do |ruser|
      [ruser.user, reviews.where(review_user: ruser).sort_by { |rev| exercise_ids.find_index rev.review_exercise.exercise.id }]
    end

    {
      exercises: exercises,
      reviews: revs
    }
  end

  def metadata(review)
    incompleted = reviews.incomplete.decided
    {
      exercise_remaining: incompleted.where(review_exercise: review.review_exercise).count,
      user_remaining: incompleted.where(review_user: review.review_user).count,
      remaining: incompleted.count,
      undecided: reviews.undecided.count,
      total: reviews.count
    }
  end

  private

  def manage_reviews
    review_users.to_a.shuffle.each do |ru|
      review_exercises.to_a.shuffle.each do |re|
        reviews.new(review_user: ru, review_exercise: re) if reviews.find_by(review_user: ru, review_exercise: re).blank?
      end
    end
  end

  def manage_user_notifications
    Notification.where(notifiable: self)&.destroy_all
    return unless released

    users.find_each do |user|
      Notification.create(notifiable: self, user_id: user_id, message: 'annotations.index.review_released')
    end
  end

  def destroy_notification
    Notification.where(notifiable: self)&.destroy_all
  end
end
