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
  has_many :reviews, dependent: :destroy

  validates :series_id, presence: true
  validates :deadline, presence: true

  after_save :manage_user_notifications
  before_destroy :destroy_notification

  def create_review_session(exercises, users)
    exercises.each do |exercise_id|
      r = review_exercises.create(exercise_id: exercise_id)
      users.each do |user_id|
        reviews.create(user_id: user_id, review_exercise: r)
      end
    end
  end

  def remove_user(user_id)
    reviews.where(user_id: user_id).destroy_all
  end

  def remove_exercise(exercise_id)
    review_exercises.where(exercise_id: exercise_id).destroy_all
  end

  def add_user(user_id)
    review_exercises.each do |review_exercise|
      reviews.create(user_id: user_id, review_exercise: review_exercise)
    end
  end

  def add_exercise(exercise_id)
    user_ids = reviews.pluck(:user_id).uniq
    r = review_exercises.create(exercise_id: exercise_id)
    user_ids.each do |user_id|
      reviews.create(user_id: user_id, review_exercise: r)
    end
  end

  def remove_exercises(exercises_to_remove)
    exercises_to_remove.each do |exercise_id|
      remove_exercise(exercise_id)
    end
  end

  def add_exercises(exercises_to_add)
    exercises_to_add.each do |exercise_id|
      add_exercise(exercise_id)
    end
  end

  def remove_users(users_to_remove)
    users_to_remove.each do |user_id|
      remove_user(user_id)
    end
  end

  def add_users(users_to_add)
    users_to_add.each do |user_id|
      add_user(user_id)
    end
  end

  def update_session(params)
    # Remove all exercises that are no longer required
    if params[:review_session][:exercises]
      params_exercise_ids = (params[:review_session][:exercises]).map(&:to_i)
      review_exercises_to_remove = review_exercises.where.not(exercise_id: params_exercise_ids).map(&:exercise_id)
      remove_exercises(review_exercises_to_remove)

      review_exercises_available = review_exercises.map(&:exercise_id)
      new_review_exercises = (params_exercise_ids || []) - review_exercises_available
      add_exercises(new_review_exercises)
    end

    # Remove each user that is no longer wanted in the review session
    if params[:review_session][:users]
      params_user_ids = (params[:review_session][:users]).map(&:to_i)
      users_to_remove = reviews.where.not(user_id: params_user_ids).map(&:user_id).uniq
      remove_users(users_to_remove)

      users_available = reviews.map(&:user_id).uniq
      new_users = (params_user_ids || []) - users_available
      add_users(new_users)
    end

    if params[:review_session][:deadline] != deadline
      update(deadline: params[:review_session][:deadline])
      reviews.map(&:save)
    end

    self.released = params[:review_session][:released]
  end

  def review_sheet
    exercises = review_exercises.includes(:exercise).map(&:exercise)
    exercise_ids = exercises.pluck(:id)
    users = reviews.includes(:user).map(&:user).uniq

    revs = users.map do |user|
      [user, reviews.where(user: user).sort_by { |rev| exercise_ids.find_index rev.review_exercise.exercise.id }]
    end

    {
      exercises: exercises,
      reviews: revs
    }
  end

  def review_siblings(review)
    reviews_same_exercise = reviews.where.not(submission: nil).where(review_exercise: review.review_exercise).order(:id)
    reviews_same_user = reviews.where.not(submission: nil).where(user: review.user).order(:id)
    {
      id: {
        prev: reviews.where.not(submission: nil).where('id < :ref_id', ref_id: review.id).last,
        next: reviews.where.not(submission: nil).find_by('id > :ref_id', ref_id: review.id)
      },
      exercise: {
        prev: reviews_same_exercise.where('id < :ref_id', ref_id: review.id).last,
        next: reviews_same_exercise.find_by('id > :ref_id', ref_id: review.id)
      },
      user: {
        prev: reviews_same_user.where('id < :ref_id', ref_id: review.id).last,
        next: reviews_same_user.find_by('id > :ref_id', ref_id: review.id)
      }
    }
  end

  def metadata(review)
    incompleted = reviews.incomplete.decided
    {
      exercise_remaining: incompleted.where(review_exercise: review.review_exercise).count,
      user_remaining: incompleted.where(user: review.user).count,
      remaining: incompleted.count,
      undecided: reviews.undecided.count,
      total: reviews.count
    }
  end

  def manage_user_notifications
    Notification.where(notifiable: self)&.destroy_all
    return unless released

    reviews.pluck(:user_id).uniq.each do |user_id|
      Notification.create(notifiable: self, user_id: user_id, message: 'annotations.index.review_released')
    end
  end

  def destroy_notification
    Notification.where(notifiable: self)&.destroy_all
  end
end
