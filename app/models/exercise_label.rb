# == Schema Information
#
# Table name: exercise_labels
#
# id           :integer  not null, primary key
# exercise_id  :integer  not null
# label_id     :integer  not null
class ExerciseLabel < ApplicationRecord
  belongs_to :exercise
  belongs_to :label
end
