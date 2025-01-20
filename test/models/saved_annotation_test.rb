# == Schema Information
#
# Table name: saved_annotations
#
#  id                :bigint           not null, primary key
#  annotation_text   :text(16777215)
#  annotations_count :integer          default(0)
#  title             :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_id         :integer
#  exercise_id       :integer
#  user_id           :integer          not null
#
require 'test_helper'

class SavedAnnotationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test 'filtering by course_id should contain nil values' do
    user = create :user
    course = create :course
    s1 = create :saved_annotation, course: nil, user: user
    s2 = create :saved_annotation, course: course, user: user
    s3 = create :saved_annotation, course: create(:course), user: user

    assert_includes SavedAnnotation.by_course_id(course.id), s1
    assert_includes SavedAnnotation.by_course_id(course.id), s2
    assert_not_includes SavedAnnotation.by_course_id(course.id), s3
  end

  test 'filtering by exercise_id should contain nil values' do
    user = create :user
    exercise = create :exercise
    s1 = create :saved_annotation, exercise: nil, user: user
    s2 = create :saved_annotation, exercise: exercise, user: user
    s3 = create :saved_annotation, exercise: create(:exercise), user: user

    assert_includes SavedAnnotation.by_exercise_id(exercise.id), s1
    assert_includes SavedAnnotation.by_exercise_id(exercise.id), s2
    assert_not_includes SavedAnnotation.by_exercise_id(exercise.id), s3
  end
end
