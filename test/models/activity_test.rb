# == Schema Information
#
# Table name: exercises
#
#  id                      :integer          not null, primary key
#  name_nl                 :string(255)
#  name_en                 :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  path                    :string(255)
#  description_format      :string(255)
#  repository_id           :integer
#  judge_id                :integer
#  status                  :integer          default("ok")
#  access                  :integer          default("public"), not null
#  programming_language_id :bigint
#  search                  :string(4096)
#  access_token            :string(16)       not null
#  repository_token        :string(64)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#

require 'test_helper'

class ActivityTest < ActiveSupport::TestCase
  setup do
    @date = DateTime.new(1302, 7, 11, 13, 37, 42)
    @user = create :user
    @exercise = create :exercise
  end

  test 'factory should create exercise' do
    assert_not_nil @exercise
  end

  test 'converting an exercise to a content page and back should retain submissions' do
    exercise = create :exercise, submission_count: 10
    exercise_id = exercise.id
    assert_equal 10, exercise.submissions.count

    # Convert the Exercise to a ContentPage.
    exercise.update(type: ContentPage.name)
    exercise.save

    # Fetch the ContentPage from the database.
    content_page_activity = Activity.find(exercise_id)
    assert_instance_of ContentPage, content_page_activity

    # Convert the ContentPage back to an Exercise.
    content_page_activity.update(type: Exercise.name)
    content_page_activity.save

    # Fetch the Exercise from the database.
    exercise_activity = Activity.find(exercise_id)
    assert_instance_of Exercise, exercise_activity
    assert_equal 10, exercise_activity.submissions.count
  end
end
