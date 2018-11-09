# == Schema Information
#
# Table name: exercise_labels
#
#  id          :bigint(8)        not null, primary key
#  exercise_id :integer          not null
#  label_id    :bigint(8)        not null
#

class ExerciseLabel < ApplicationRecord
  belongs_to :exercise
  belongs_to :label
end
