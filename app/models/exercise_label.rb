# == Schema Information
#
# Table name: exercise_labels
#
#  id          :bigint           not null, primary key
#  exercise_id :integer          not null
#  label_id    :bigint           not null
#

class ExerciseLabel < ApplicationRecord
  belongs_to :exercise
  belongs_to :label
end
