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
#  institution_id :bigint(8)
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

  test 'course scoresheet should be correct' do
    course = create :course
    create_list :series, 4, course: course, exercise_count: 5, deadline: Time.current
    users = create_list(:user, 4, courses: [course])

    course.series.each do |series|
      deadline = series.deadline
      series.exercises.map do |exercise|
        4.times do |i|
          u = users[i]
          case i
          when 0 # Wrong submission before deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes)
          when 1 # Correct submission before deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes)
          when 2 # Wrong submission after deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes)
          when 3 # Correct submission after deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes)
          end
        end
      end
    end
    scoresheet = course.scoresheet
    kommas = (3 + course.series.count) * (2 + users.count)
    assert_equal kommas, scoresheet.count(',')
  end
end
