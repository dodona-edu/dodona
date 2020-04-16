class ExerciseStatus < ApplicationRecord
  belongs_to :exercise
  belongs_to :series, optional: true
  belongs_to :user
end
