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

  setup do
    @date = DateTime.new(1302, 7, 11, 13, 37, 42)
    @user = create :user
    @exercise = create :exercise
    other_user = create :user

    create :wrong_submission,
           user: other_user,
           exercise: @exercise
    create :correct_submission,
           user: other_user,
           exercise: @exercise
  end

  test 'factory should create exercise' do
    assert_not_nil @exercise
  end

  test 'exercise name should respect locale and not be nil' do
    I18n.with_locale :en do
      assert_equal @exercise.name_en, @exercise.name
    end
    I18n.with_locale :nl do
      assert_equal @exercise.name_nl, @exercise.name

      @exercise.name_nl = nil
      assert_equal @exercise.name_en, @exercise.name

      @exercise.name_en = nil
      assert_equal @exercise.path.split('/').last, @exercise.name
    end
  end

  test 'users tried' do
    e = create :exercise
    course1 = create :course
    create :series, course: course1, exercises: [e]
    course2 = create :course
    create :series, course: course2, exercises: [e]

    users_c1 = create_list(:user, 5, courses: [course1])
    users_c2 = create_list(:user, 5, courses: [course2])
    users_all = create_list(:user, 5, courses: [course1, course2])

    assert_equal 0, e.users_tried
    assert_equal 0, e.users_tried(course1)
    assert_equal 0, e.users_tried(course2)

    create :submission, user: users_c1[0], exercise: e

    assert_equal 1, e.users_tried
    assert_equal 1, e.users_tried(course1)
    assert_equal 0, e.users_tried(course2)

    create :submission, user: users_c2[0], exercise: e

    assert_equal 2, e.users_tried
    assert_equal 1, e.users_tried(course1)
    assert_equal 1, e.users_tried(course2)

    create :submission, user: users_all[0], exercise: e

    assert_equal 3, e.users_tried
    assert_equal 2, e.users_tried(course1)
    assert_equal 2, e.users_tried(course2)

    users_c1.each do |user|
      create :submission, user: user, exercise: e
    end
    assert_equal 7, e.users_tried
    assert_equal 6, e.users_tried(course1)
    assert_equal 2, e.users_tried(course2)

    users_c2.each do |user|
      create :submission, user: user, exercise: e
    end
    assert_equal 11, e.users_tried
    assert_equal 6, e.users_tried(course1)
    assert_equal 6, e.users_tried(course2)
    users_all.each do |user|
      create :submission, user: user, exercise: e
    end
    assert_equal 15, e.users_tried
    assert_equal 10, e.users_tried(course1)
    assert_equal 10, e.users_tried(course2)
  end

  test 'last submission' do
    assert_nil @exercise.last_submission(@user)

    first = create :wrong_submission,
                   user: @user,
                   exercise: @exercise,
                   created_at: @date

    assert_equal first, @exercise.last_submission(@user)

    assert_nil @exercise.last_submission(@user, @date - 1.second)

    second = create :correct_submission,
                    user: @user,
                    exercise: @exercise,
                    created_at: @date + 1.minute

    assert_equal second, @exercise.last_submission(@user)
    assert_equal first, @exercise.last_submission(@user, @date + 10.seconds)
  end

  test 'last correct submission' do
    assert_nil @exercise.last_correct_submission(@user)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date

    assert_nil @exercise.last_correct_submission(@user)

    correct = create :correct_submission,
                     user: @user,
                     exercise: @exercise,
                     created_at: @date + 1.second

    assert_equal correct, @exercise.last_correct_submission(@user)
    assert_nil @exercise.last_correct_submission(@user, @date - 1.second)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 2.seconds

    assert_equal correct, @exercise.last_correct_submission(@user)
  end

  test 'best submission' do
    assert_nil @exercise.best_submission(@user)

    wrong = create :wrong_submission,
                   user: @user,
                   exercise: @exercise,
                   created_at: @date

    assert_equal wrong, @exercise.best_submission(@user)

    correct = create :correct_submission,
                     user: @user,
                     exercise: @exercise,
                     created_at: @date + 10.seconds

    assert_equal correct, @exercise.best_submission(@user)
    assert_equal wrong, @exercise.best_submission(@user, @date + 1.second)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 1.minute

    assert_equal correct, @exercise.best_submission(@user)
  end

  test 'best is last submission' do
    assert @exercise.best_is_last_submission?(@user)

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date

    assert @exercise.best_is_last_submission?(@user)
    assert @exercise.best_is_last_submission?(@user, @date - 10.seconds)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 10.seconds

    assert_not @exercise.best_is_last_submission?(@user)
    assert @exercise.best_is_last_submission?(@user, @date + 5.seconds)
  end

  test 'accepted for' do
    assert_not @exercise.accepted_for(@user)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date

    assert_not @exercise.accepted_for(@user)

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 10.seconds

    assert @exercise.accepted_for(@user)
    assert_not @exercise.accepted_for(@user, @date + 5.seconds)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 1.minute

    assert_not @exercise.accepted_for(@user)
  end


end
