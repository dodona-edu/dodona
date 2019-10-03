# == Schema Information
#
# Table name: courses
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  year           :string(255)
#  secret         :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  description    :text(65535)
#  visibility     :integer          default("visible_for_all")
#  registration   :integer          default("open_for_all")
#  color          :integer
#  teacher        :string(255)      default("")
#  institution_id :bigint
#  search         :string(4096)
#  moderated      :boolean          default(FALSE), not null
#

require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  test 'factory should create course' do
    course = create :course
    assert_not_nil course
    assert_not course.secret.blank?
  end

  test 'course formatted year should not have spaces' do
    course = create :course, year: '2017 - 2018'
    assert_equal '2017–2018', course.formatted_year
  end

  test 'hidden course should always require secret' do
    course = create :course, institution: (create :institution), visibility: :hidden
    user1 = create :user, institution: nil
    user2 = create :user, institution: course.institution
    user3 = create :user, institution: (create :institution)

    assert course.secret_required?
    assert course.secret_required?(user1)
    assert course.secret_required?(user2)
    assert course.secret_required?(user3)
  end

  test 'visible_for_institution course should not require secret for user of institution' do
    course = create :course, institution: (create :institution), visibility: :visible_for_institution
    user1 = create :user, institution: nil
    user2 = create :user, institution: course.institution
    user3 = create :user, institution: (create :institution)

    assert course.secret_required?
    assert course.secret_required?(user1)
    assert_not course.secret_required?(user2)
    assert course.secret_required?(user3)
  end

  test 'visible_for_all course should never require secret' do
    course = create :course, institution: (create :institution), visibility: :visible_for_all
    user1 = create :user, institution: nil
    user2 = create :user, institution: course.institution
    user3 = create :user, institution: (create :institution)

    assert_not course.secret_required?
    assert_not course.secret_required?(user1)
    assert_not course.secret_required?(user2)
    assert_not course.secret_required?(user3)
  end
end
