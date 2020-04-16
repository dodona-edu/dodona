class ExerciseStatus < ApplicationRecord
  belongs_to :exercise
  belongs_to :series, optional: true
  belongs_to :user

  scope :in_course, ->(course) { where(course: course) }
  scope :by_exercise, ->(exercise) { where(exercise: exercise) }
  scope :by_user, ->(user) { where(user: user) }
end
