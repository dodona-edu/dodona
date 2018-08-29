class ExerciseTag < ApplicationRecord
  belongs_to :exercise
  belongs_to :tag
end
