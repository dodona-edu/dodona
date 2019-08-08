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
#  token                   :string(64)
#  access                  :integer          default("public"), not null
#  programming_language_id :bigint(8)
#  search                  :string(4096)
#  access_token            :string(16)       not null
#

require 'test_helper'

class ExerciseTest < ActiveSupport::TestCase
  setup do
    @date = DateTime.new(1302, 7, 11, 13, 37, 42)
    @user = create :user
    @exercise = create :exercise
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
    assert_equal 0, e.users_tried(course: course1)
    assert_equal 0, e.users_tried(course: course2)

    create :submission, user: users_c1[0], course: course1, exercise: e

    assert_equal 1, e.users_tried
    assert_equal 1, e.users_tried(course: course1)
    assert_equal 0, e.users_tried(course: course2)

    create :submission, user: users_c2[0], course: course2, exercise: e

    assert_equal 2, e.users_tried
    assert_equal 1, e.users_tried(course: course1)
    assert_equal 1, e.users_tried(course: course2)

    create :submission, user: users_all[0], exercise: e

    assert_equal 3, e.users_tried
    assert_equal 1, e.users_tried(course: course1)
    assert_equal 1, e.users_tried(course: course2)

    users_c1.each do |user|
      create :submission, user: user, course: course1, exercise: e
    end
    assert_equal 7, e.users_tried
    assert_equal 5, e.users_tried(course: course1)
    assert_equal 1, e.users_tried(course: course2)

    users_c2.each do |user|
      create :submission, user: user, course: course2, exercise: e
    end
    assert_equal 11, e.users_tried
    assert_equal 5, e.users_tried(course: course1)
    assert_equal 5, e.users_tried(course: course2)
    users_all.each do |user|
      create :submission, user: user, exercise: e
    end
    assert_equal 15, e.users_tried
    assert_equal 5, e.users_tried(course: course1)
    assert_equal 5, e.users_tried(course: course2)
  end

  test 'users correct' do
    e = create :exercise
    course1 = create :course
    create :series, course: course1, exercises: [e]
    course2 = create :course
    create :series, course: course2, exercises: [e]

    user_c1 = create :user, courses: [course1]
    user_c2 = create :user, courses: [course2]
    user_all = create :user, courses: [course1, course2]

    assert_equal 0, e.users_correct
    assert_equal 0, e.users_correct(course: course1)
    assert_equal 0, e.users_correct(course: course2)

    create :wrong_submission, user: user_c1, course: course1, exercise: e
    assert_equal 0, e.users_correct
    assert_equal 0, e.users_correct(course: course1)
    assert_equal 0, e.users_correct(course: course2)

    create :correct_submission, user: user_c1, course: course1, exercise: e
    assert_equal 1, e.users_correct
    assert_equal 1, e.users_correct(course: course1)
    assert_equal 0, e.users_correct(course: course2)

    create :wrong_submission, user: user_c2, course: course2, exercise: e
    assert_equal 1, e.users_correct
    assert_equal 1, e.users_correct(course: course1)
    assert_equal 0, e.users_correct(course: course2)

    create :correct_submission, user: user_c2, course: course2, exercise: e
    assert_equal 2, e.users_correct
    assert_equal 1, e.users_correct(course: course1)
    assert_equal 1, e.users_correct(course: course2)

    create :wrong_submission, user: user_all, exercise: e
    assert_equal 2, e.users_correct
    assert_equal 1, e.users_correct(course: course1)
    assert_equal 1, e.users_correct(course: course2)

    create :correct_submission, user: user_all, exercise: e
    assert_equal 3, e.users_correct
    assert_equal 1, e.users_correct(course: course1)
    assert_equal 1, e.users_correct(course: course2)
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

  test 'exercise not made within course should not be accepted for that course' do
    series = create_list :series, 2, exercises: [@exercise]
    courses = series.map(&:course)

    create :correct_submission,
           user: @user,
           exercise: @exercise

    courses.each do |course|
      assert_not @exercise.accepted_for(@user, nil, course)
    end

    create :wrong_submission,
           user: @user,
           exercise: @exercise

    courses.each do |course|
      assert_not @exercise.accepted_for(@user, nil, course)
    end

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           course: courses[0]

    assert @exercise.accepted_for(@user, nil, courses[0])
    assert_not @exercise.accepted_for(@user, nil, courses[1])

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           course: courses[1]

    courses.each do |course|
      assert @exercise.accepted_for(@user, nil, course)
    end
  end
end

class ExerciseRemoteTest < ActiveSupport::TestCase
  setup do
    # allow pushing
    Rails.env.stubs(:production?).returns(true)
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_exercises
    @exercise = @repository.exercises.first
  end

  teardown do
    @remote.remove
    @repository.git_repository.remove
  end

  def config
    JSON.parse(File.read(@exercise.config_file))
  end

  test 'should update access in config file' do
    @exercise.update access: 'private'
    assert_equal 'private', config['access']
  end

  test 'should update name_nl in config file' do
    @exercise.update name_nl: 'Echo'
    assert_equal 'Echo', config['description']['names']['nl']
  end

  test 'should update name_en in config file' do
    @exercise.update name_en: 'Echo'
    assert_equal 'Echo', config['description']['names']['en']
  end

  test 'should use current user name when committing' do
    Current.user = create :user
    @exercise.update access: 'private'
    assert_equal Current.user.full_name, @remote.git('log', '-1', '--pretty=format:%an')
  end

  test 'should use current user email when committing' do
    Current.user = create :user
    @exercise.update access: 'private'
    assert_equal Current.user.email, @remote.git('log', '-1', '--pretty=format:%ae')
  end

  test 'should push to remote' do
    assert_difference('@remote.commit_count', 1) do
      @exercise.update access: 'private'
    end
  end

  test 'should push changes' do
    @exercise.update access: 'private'
    config = JSON.parse(
      File.read(File.join(@remote.path, @exercise.path, 'config.json'))
    )
    assert_equal 'private', config['access']
  end
end

# multiple layers of configurations; tests merging.
class LasagneConfigTest < ActiveSupport::TestCase
  setup do
    @judge = create :judge, :git_stubbed, name: 'Iona Nikitchenko'
    @remote = local_remote('exercises/lasagna')
    @repository = create :repository, remote: @remote.path
    @repository.process_exercises
    @exercise = @repository.exercises.first
  end

  teardown do
    @remote.remove
    @repository.git_repository.remove
  end

  # set top level, overridden by exercise
  test 'should set judge' do
    assert_equal @judge, @exercise.judge
  end

  # set at top level, overridden by series, overridden by exercise
  test 'should set programming language' do
    assert_equal ProgrammingLanguage.find_by(name: 'python'), @exercise.programming_language
  end

  # set at top level, overridden by series
  test 'should set access' do
    assert_equal 'public', @exercise.access
  end

  test 'should set config values from dirconfig in reporoot' do
    assert_not @exercise.config.key? 'root_config'
    assert @exercise.merged_config.key? 'root_config'
    assert_equal 'set', @exercise.merged_config['root_config']
  end

  # set at top level, overridden by series, not set at exercise
  test 'should not write access if initially not present' do
    assert_equal 'public', @exercise.access
    @exercise.update_config
    assert_not @exercise.config.key? 'access'
  end

  test 'should add labels to config file when exercise is updated' do
    @exercise.update(labels: [])
    assert_equal [], @exercise.config['labels']
    @exercise.update(labels: [Label.create(name: 'new label')])
    assert_equal ['new label'], @exercise.config['labels']
  end

  # set at top level, overridden by series, not set at exercise
  test 'should override parent config access if manually changed' do
    assert_not @exercise.config.key? 'access'
    assert @exercise.merged_config.key? 'access'
    assert_equal 'public', @exercise.access

    @exercise.update_config
    assert_not @exercise.config.key? 'access'

    @exercise.access = 'public'
    @exercise.update_config
    assert_not @exercise.config.key? 'access'

    @exercise.access = 'private'
    @exercise.update_config
    assert_equal 'private', @exercise.config['access']
    assert_equal 'private', @exercise.merged_config['access']
  end

  test 'should merge label arrays' do
    assert_equal 4, @exercise.labels.count
  end

  test 'should update child configs if dirconfig has a memory limit that is too high' do
    assert_equal 500_000_000, @exercise.config['evaluation']['memory_limit']
  end
end
