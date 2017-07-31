# == Schema Information
#
# Table name: exercises
#
#  id                   :integer          not null, primary key
#  name_nl              :string(255)
#  name_en              :string(255)
#  visibility           :integer          default("open")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  path                 :string(255)
#  description_format   :string(255)
#  programming_language :string(255)
#  repository_id        :integer
#  judge_id             :integer
#  status               :integer          default("ok")
#

require 'test_helper'

class ExerciseTest < ActiveSupport::TestCase
  test 'factory' do
    create :exercise
  end

  test 'exercise name should respect locale and not be nil' do
    exercise = create :exercise
    I18n.with_locale :en do
      assert_equal exercise.name_en, exercise.name
    end
    I18n.with_locale :nl do
      assert_equal exercise.name_nl, exercise.name

      exercise.name_nl = nil
      assert_equal exercise.name_en, exercise.name

      exercise.name_en = nil
      assert_equal exercise.path.split('/').last, exercise.name
    end
  end
end
