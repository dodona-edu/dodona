# == Schema Information
#
# Table name: evaluations
#
#  id         :bigint           not null, primary key
#  series_id  :integer
#  released   :boolean          default(FALSE), not null
#  deadline   :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Evaluation < ApplicationRecord
  belongs_to :series

  has_many :annotations, dependent: :destroy
  has_many :evaluation_exercises, dependent: :destroy
  has_many :evaluation_users, dependent: :destroy
  has_many :feedbacks, dependent: :destroy

  has_many :users, through: :evaluation_users
  has_many :exercises, through: :evaluation_exercises

  validates :deadline, presence: true
  validate :deadline_in_past

  before_save :manage_feedbacks
  before_destroy :destroy_notification
  after_save :manage_user_notifications

  def users=(new_users)
    removed = users - new_users
    evaluation_users.where(user: removed).destroy_all
    super(new_users)
  end

  def exercises=(new_exercises)
    removed = exercises - new_exercises
    evaluation_exercises.where(exercise: removed).destroy_all
    super(new_exercises)
  end

  def metadata
    {
      done: feedbacks.complete.count,
      total: feedbacks.count,
      next_incomplete_feedback: feedbacks.incomplete.order(id: :asc).first,
      per_exercise: exercises.map do |ex|
        fbs = feedbacks.includes(:evaluation_exercise).where(evaluation_exercises: { exercise_id: ex.id })
        {
          exercise: ex,
          name: ex.name,
          done: fbs.complete.count,
          total: fbs.count,
          next_incomplete_feedback: fbs.incomplete.order(id: :asc).first
        }
      end
    }
  end

  def evaluation_sheet
    exercises = evaluation_exercises.includes(:exercise).map(&:exercise)
    exercise_ids = exercises.pluck(:id)
    users = evaluation_users.includes(:user).map(&:user)

    all_feedbacks = feedbacks.includes(:submission, evaluation_exercise: [:exercise], evaluation_user: [:user]).to_a
    fbs = users.map do |user|
      [user.id, all_feedbacks.select { |fb| fb.evaluation_user.user == user }.sort_by { |fb| exercise_ids.find_index fb.evaluation_exercise.exercise.id }]
    end.to_h

    {
      exercises: exercises,
      feedbacks: fbs
    }
  end

  private

  def deadline_in_past
    errors.add(:deadline, I18n.t('deadlines.validate.should_be_in_past')) if deadline.present? && deadline > Time.current
  end

  def manage_feedbacks
    existing = feedbacks.to_a
    evaluation_users.to_a.each do |eu|
      evaluation_exercises.to_a.each do |ee|
        feedbacks.new(evaluation_user: eu, evaluation_exercise: ee) if existing.select { |f| f.evaluation_user == eu && f.evaluation_exercise == ee }.blank?
      end
    end
  end

  def manage_user_notifications
    Notification.where(notifiable: self)&.destroy_all
    return unless released

    users.find_each do |user|
      Notification.create(notifiable: self, user_id: user.id, message: 'evaluations.overview.released')
    end
  end

  def destroy_notification
    Notification.where(notifiable: self)&.destroy_all
  end
end
