# == Schema Information
#
# Table name: activities
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
#  type                    :string(255)      default("Exercise"), not null
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

  test 'accessible? should return false if user is course admin of course and exercise not in course' do
    exercise = create :exercise
    course = create :course, users: [@user]
    User.any_instance.stubs(:course_admin?).returns(true)
    assert_not exercise.accessible?(@user, course)
  end

  test 'accessible? should return false if user is not course admin of course and exercise is not in course' do
    exercise = create :exercise
    course = create :course, users: [@user]
    assert_not exercise.accessible?(@user, course)
  end

  test 'accessible? should return false if user is not course admin of course and series is not visible course' do
    exercise = create :exercise
    course = create :course, users: [@user]
    create :series, course: course, visibility: 'closed', exercises: [exercise]
    assert_not exercise.accessible?(@user, course)
  end

  test 'accessible? should return true if user is course admin of course, repository admin and exercise is in course' do
    exercise = create :exercise
    course = create :course, users: [@user]
    User.any_instance.stubs(:course_admin?).returns(true)
    User.any_instance.stubs(:repository_admin?).returns(true)
    create :series, course: course, exercises: [exercise]
    assert exercise.accessible?(@user, course)
  end

  test 'accessible? should return true if user is repository admin and series is visible' do
    exercise = create :exercise
    course = create :course
    User.any_instance.stubs(:repository_admin?).returns(true)
    create :series, course: course, exercises: [exercise]
    assert exercise.accessible?(@user, course)
  end

  test 'accessible? should return false if not allowed to use exercise' do
    exercise = create :exercise, access: 'private'
    course = create :course
    create :series, course: course, exercises: [exercise]
    assert_not exercise.accessible?(@user, course)
  end

  test 'accessible? should return true if repository allows access to course' do
    exercise = create :exercise, access: :private
    course = create :course
    create :series, course: course, exercises: [exercise]
    exercise.repository.allowed_courses << course
    assert exercise.accessible?(@user, course)
  end

  test 'accessible? should return false if user is not a member of the course' do
    exercise = create :exercise
    course = create :course, registration: 'closed'
    create :series, course: course, exercises: [exercise]
    assert_not exercise.accessible?(@user, course)
  end

  test 'accessible? should return true if user is a member of the course' do
    exercise = create :exercise
    course = create :course, users: [@user]
    create :series, course: course, exercises: [exercise]
    assert exercise.accessible?(@user, course)
  end

  test 'accessible? should return true if user repository admin of repository' do
    exercise = create :exercise, access: 'private'
    User.any_instance.stubs(:repository_admin?).returns(true)
    assert exercise.accessible?(@user, nil)
  end

  test 'accessible? should return true if exercise is public' do
    exercise = create :exercise
    assert exercise.accessible?(@user, nil)
  end

  test 'accessible? should return false if exercise is private' do
    exercise = create :exercise, access: 'private'
    assert_not exercise.accessible?(@user, nil)
  end

  test 'exercise should be accessible if private and included in unmoderated open course' do
    exercise = create :exercise, access: 'private'
    course = create :course, moderated: false, registration: :open_for_all
    exercise.repository.allowed_courses << course
    create :series, course: course, exercises: [exercise]
    assert exercise.accessible?(@user, course)
  end

  test 'exercise should not be accessible if private and included in a moderated but open course' do
    exercise = create :exercise, access: 'private'
    course = create :course, moderated: true, registration: :open_for_all
    exercise.repository.allowed_courses << course
    create :series, course: course, exercises: [exercise]
    assert_not exercise.accessible?(@user, course)
  end

  test 'convert_visibility_to_access should convert "visible" to "public"' do
    assert_equal 'public', Exercise.convert_visibility_to_access('visible')
  end

  test 'convert_visibility_to_access should convert "open" to "public"' do
    assert_equal 'public', Exercise.convert_visibility_to_access('open')
  end

  test 'convert_visibility_to_access should convert "invisible" to "private"' do
    assert_equal 'private', Exercise.convert_visibility_to_access('invisible')
  end

  test 'convert_visibility_to_access should convert "hidden" to "private"' do
    assert_equal 'private', Exercise.convert_visibility_to_access('hidden')
  end

  test 'convert_visibility_to_access should convert "closed" to "private"' do
    assert_equal 'private', Exercise.convert_visibility_to_access('closed')
  end

  test 'convert_visibility_to_access should convert "other" to "other"' do
    assert_equal 'other', Exercise.convert_visibility_to_access('other')
  end

  test 'move_relations should move submissions from one exercise to the other' do
    exercise1 = create :exercise
    create :submission, exercise: exercise1
    exercise2 = create :exercise
    assert_equal 1, exercise1.submissions.count
    assert_equal 0, exercise2.submissions.count
    Exercise.move_relations(exercise1, exercise2)
    assert_equal 0, exercise1.submissions.count
    assert_equal 1, exercise2.submissions.count
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

    create :submission, user: users_c1[0], course: course1, exercise: e, status: :wrong

    assert_equal 1, e.users_tried
    assert_equal 1, e.users_tried(course: course1)
    assert_equal 0, e.users_tried(course: course2)

    create :submission, user: users_c2[0], course: course2, exercise: e, status: :wrong

    assert_equal 2, e.users_tried
    assert_equal 1, e.users_tried(course: course1)
    assert_equal 1, e.users_tried(course: course2)

    create :submission, user: users_all[0], exercise: e, status: :wrong

    assert_equal 3, e.users_tried
    assert_equal 1, e.users_tried(course: course1)
    assert_equal 1, e.users_tried(course: course2)

    users_c1.each do |user|
      create :submission, user: user, course: course1, exercise: e, status: :wrong
    end
    assert_equal 7, e.users_tried
    assert_equal 5, e.users_tried(course: course1)
    assert_equal 1, e.users_tried(course: course2)

    users_c2.each do |user|
      create :submission, user: user, course: course2, exercise: e, status: :wrong
    end
    assert_equal 11, e.users_tried
    assert_equal 5, e.users_tried(course: course1)
    assert_equal 5, e.users_tried(course: course2)
    users_all.each do |user|
      create :submission, user: user, exercise: e, status: :wrong
    end
    assert_equal 15, e.users_tried
    assert_equal 5, e.users_tried(course: course1)
    assert_equal 5, e.users_tried(course: course2)
    users_all.each do |user|
      create :submission, user: user, exercise: e, status: :running
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

  test 'solved_for' do
    create :wrong_submission,
           exercise: @exercise,
           user: @user

    assert_equal false, @exercise.solved_for?(@user)

    create :correct_submission,
           exercise: @exercise,
           user: @user

    assert_equal true, @exercise.solved_for?(@user)
  end

  test 'solved_for should retry finding ActivityStatus when it fails once' do
    create :wrong_submission,
           exercise: @exercise,
           user: @user

    ActivityStatus.stubs(:find_or_create_by)
                  .raises(StandardError.new('This is an error')).then
                  .returns(ActivityStatus.find_by(activity: @exercise, user: @user))
    assert_equal false, @exercise.solved_for?(@user)
  end

  test 'solved_for should not retry finding ActivityStatus when it fails twice' do
    create :wrong_submission,
           exercise: @exercise,
           user: @user

    ActivityStatus.stubs(:find_or_create_by)
                  .raises(StandardError.new('This is an error')).then
                  .raises(StandardError.new('This is an error'))
    assert_raises StandardError do
      @exercise.activity_status_for!(@user)
    end
  end

  test 'last submission' do
    assert_nil @exercise.last_submission!(@user)

    first = create :wrong_submission,
                   user: @user,
                   exercise: @exercise,
                   created_at: @date

    assert_equal first, @exercise.last_submission!(@user)

    assert_nil @exercise.last_submission!(@user, @date - 1.second)

    second = create :correct_submission,
                    user: @user,
                    exercise: @exercise,
                    created_at: @date + 1.minute

    assert_equal second, @exercise.last_submission!(@user)
    assert_equal first, @exercise.last_submission!(@user, @date + 10.seconds)
  end

  test 'last correct submission' do
    assert_nil @exercise.last_correct_submission!(@user)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date

    assert_nil @exercise.last_correct_submission!(@user)

    correct = create :correct_submission,
                     user: @user,
                     exercise: @exercise,
                     created_at: @date + 1.second

    assert_equal correct, @exercise.last_correct_submission!(@user)
    assert_nil @exercise.last_correct_submission!(@user, @date - 1.second)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 2.seconds

    assert_equal correct, @exercise.last_correct_submission!(@user)
  end

  test 'best submission' do
    assert_nil @exercise.best_submission!(@user)

    wrong = create :wrong_submission,
                   user: @user,
                   exercise: @exercise,
                   created_at: @date

    assert_equal wrong, @exercise.best_submission!(@user)

    correct = create :correct_submission,
                     user: @user,
                     exercise: @exercise,
                     created_at: @date + 10.seconds

    assert_equal correct, @exercise.best_submission!(@user)
    assert_equal wrong, @exercise.best_submission!(@user, @date + 1.second)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 1.minute

    assert_equal correct, @exercise.best_submission!(@user)
  end

  test 'best is last submission' do
    assert @exercise.best_is_last_submission?(@user)

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date

    assert @exercise.best_is_last_submission?(@user)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 10.seconds

    assert_not @exercise.best_is_last_submission?(@user)
  end

  test 'accepted for' do
    assert_not @exercise.accepted_for?(@user)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date

    assert_not @exercise.accepted_for?(@user)

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 10.seconds

    assert @exercise.accepted_for?(@user)

    create :wrong_submission,
           user: @user,
           exercise: @exercise,
           created_at: @date + 1.minute

    assert_not @exercise.accepted_for?(@user)
  end

  test 'exercise status should be updated for every series in a course' do
    course = create :course
    series = create_list :series, 2, course: course, exercises: [@exercise]

    series.each do |series_it|
      assert_not @exercise.accepted_for?(@user, series_it)
    end

    create :correct_submission,
           course: course,
           exercise: @exercise,
           user: @user

    series.each do |series_it|
      assert @exercise.accepted_for?(@user, series_it)
    end
  end

  test 'exercise not made within course should not be accepted for that course' do
    series = create_list :series, 2, exercises: [@exercise]
    courses = series.map(&:course)

    create :correct_submission,
           user: @user,
           exercise: @exercise

    series.each do |series_it|
      assert_not @exercise.accepted_for?(@user, series_it)
    end

    create :wrong_submission,
           user: @user,
           exercise: @exercise

    series.each do |series_it|
      assert_not @exercise.accepted_for?(@user, series_it)
    end

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           course: courses[0]

    assert @exercise.accepted_for?(@user, series[0])
    assert_not @exercise.accepted_for?(@user, series[1])

    create :correct_submission,
           user: @user,
           exercise: @exercise,
           course: courses[1]

    series.each do |series_it|
      assert @exercise.accepted_for?(@user, series_it)
    end
  end

  test 'access token should change when access changes' do
    old_token = @exercise.access_token
    @exercise.update(access: :private)
    assert_not_equal @exercise.reload.access_token, old_token
  end

  test 'access token should not change when something else changes' do
    old_token = @exercise.access_token
    @exercise.update(name_en: 'Wubba Lubba dub-dub')
    assert_equal @exercise.reload.access_token, old_token
  end

  test 'access token should change when containing series changes visibility' do
    series = create :series, exercises: [@exercise], visibility: :open
    old_token = @exercise.access_token

    series.update(visibility: :hidden)
    hidden_token = @exercise.reload.access_token
    assert_not_equal hidden_token, old_token

    series.update(visibility: :closed)
    closed_token = @exercise.reload.access_token
    assert_not_equal closed_token, hidden_token
  end

  test 'access token should change when removed from series' do
    old_token = @exercise.access_token

    series = create :series, visibility: :open
    series.exercises << @exercise
    assert_equal old_token, @exercise.reload.access_token, 'access token should not change when added to series'

    series.exercises.destroy(@exercise)
    assert_not_equal old_token, @exercise.reload.access_token
  end

  test 'description language scope should be chainable' do
    @exercise.update description_nl_present: true, name_nl: 'Wingardium Leviosa', name_en: 'Wingardium Leviosa'
    assert_equal 1, Exercise.by_name('Wingardium Leviosa').by_description_languages(['nl']).count
  end
end

class ExerciseRemoteTest < ActiveSupport::TestCase
  setup do
    # allow pushing
    Rails.env.stubs(:production?).returns(true)
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_activities
    @exercise = @repository.exercises.first
    @about_nl_path = @exercise.full_path.join('README.nl.md')
    @about_en_path = @exercise.full_path.join('README.md')
  end

  teardown do
    @remote.remove
    @repository.git_repository.remove
  end

  def config
    JSON.parse(File.read(@exercise.config_file))
  end

  test 'should have solutions' do
    assert_equal @exercise.solutions,
                 'solution.py' => "print(input())\n",
                 'empty.py' => ''
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

  test 'dirconfig_file? should return true if the basename is "dirconfig.json"' do
    assert Exercise.dirconfig_file?(@exercise.full_path + '/dirconfig.json')
  end

  test 'dirconfig_file? should return false if the basename is not "dirconfig.json"' do
    assert_not Exercise.dirconfig_file?(@exercise.full_path + '/otherconfig.json')
  end

  test 'safe_delete should not destroy exercise if status is not removed' do
    @exercise.safe_destroy
    assert_equal @repository.exercises.first, @exercise
  end

  test 'safe_delete should destroy exercise if status is removed' do
    @exercise.status = 2 # set status to removed
    @exercise.safe_destroy
    assert_not_equal @repository.exercises.first, @exercise
  end

  test 'safe_delete should not destroy exercise if it has submissions' do
    @exercise.status = 2 # set status to removed
    user = create :user
    submission = create :submission, exercise: @exercise, user: user
    @exercise.submissions.concat(submission) # Add a submission
    @exercise.safe_destroy
    assert_equal @repository.exercises.first, @exercise
  end

  test 'safe_delete should not destroy exercise if it has series memberships' do
    @exercise.status = 2 # set status to removed
    course = create :course
    series = create :series, course: course, activity_count: 1
    series.exercises.map { @exercise }
    @exercise.series.concat(series) # Add series membership
    @exercise.safe_destroy
    assert_equal @repository.exercises.first, @exercise
  end

  test 'config_file? should be true if exercise has a config file' do
    assert @exercise.config_file?
  end

  test 'config_file? should be false if exercise has no config file' do
    @exercise.path = '/wrong_path'
    assert_not @exercise.config_file?
  end

  test 'about should give a localized result for en' do
    I18n.with_locale :en do
      assert_equal @about_en_path.read, @exercise.about
    end
  end

  test 'about should give a localized result for nl' do
    I18n.with_locale :nl do
      assert_equal @about_nl_path.read, @exercise.about
    end
  end

  test 'about should fallback to other language if localized is unavailable' do
    FileUtils.rm @about_en_path
    I18n.with_locale :en do
      assert_equal @about_nl_path.read, @exercise.about
    end
  end

  test 'about.en.md and about.nl.md shoud still be supported' do
    about_en = @about_en_path.read
    about_nl = @about_nl_path.read
    FileUtils.mv @about_en_path, @exercise.full_path.join('about.en.md')
    FileUtils.mv @about_nl_path, @exercise.full_path.join('about.nl.md')
    I18n.with_locale :en do
      assert_equal about_en, @exercise.about
    end
    I18n.with_locale :nl do
      assert_equal about_nl, @exercise.about
    end
  end

  test 'about can be in README' do
    about = File.read @about_en_path
    FileUtils.rm @about_nl_path
    FileUtils.mv @about_en_path, @exercise.full_path.join('README')
    assert_equal about, @exercise.about
  end
end

# multiple layers of configurations; tests merging.
class LasagneConfigTest < ActiveSupport::TestCase
  setup do
    @judge = create :judge, :git_stubbed, name: 'Iona Nikitchenko'
    @remote = local_remote('exercises/lasagna')
    @repository = create :repository, remote: @remote.path
    @repository.process_activities
    @exercise = @repository.exercises.find_by(path: 'exercises/series/ISBN')
    @extra_exercise = @repository.exercises.find_by(path: 'exercises/extra/echo')
  end

  teardown do
    @remote.remove
    @repository.git_repository.remove
  end

  test 'determine_format should return "md" when exercise has and md description' do
    Dir.stubs(:glob).returns([]) # The search to html descriptions should return no results because description is in md
    assert_equal 'md', Exercise.determine_format(@exercise.full_path)
  end

  test 'determine_format should return "html" when exercise has and html description' do
    assert_equal 'html', Exercise.determine_format(@exercise.full_path)
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
    assert_equal Pathname.new('dirconfig.json'),
                 @exercise.merged_config_locations['root_config']
  end

  test 'should throw ":abort" when commit does not succeed and return an error' do
    @exercise.repository.stubs(:commit).returns([false, ['not empty']])
    assert_throws :abort do
      @exercise.store_config(config)
    end
  end

  # set at top level, overridden by series, not set at exercise
  test 'should not have write access if initially not present' do
    assert_equal 'public', @exercise.access
    assert_equal Pathname.new('./exercises/series/dirconfig.json'),
                 @exercise.merged_config_locations['access']
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
    assert_equal Pathname.new('./exercises/series/dirconfig.json'),
                 @exercise.merged_config_locations['access']

    @exercise.update_config
    assert_not @exercise.config.key? 'access'

    @exercise.access = 'public'
    @exercise.update_config
    assert_not @exercise.config.key? 'access'

    @exercise.access = 'private'
    @exercise.update_config
    assert_equal 'private', @exercise.config['access']
    assert_equal 'private', @exercise.merged_config['access']
    assert_equal @exercise.config_file,
                 @exercise.merged_config_locations['access']
  end

  test 'should merge label arrays' do
    assert_equal 4, @exercise.labels.count
    expected = ['dirconfig.json',
                './exercises/dirconfig.json',
                './exercises/series/dirconfig.json',
                @exercise.config_file].map { |p| Pathname.new p }
    assert_equal expected,
                 @exercise.merged_config_locations['labels']
  end

  test 'should update child configs if dirconfig has a memory limit that is too high' do
    assert_equal 500_000_000, @exercise.config['evaluation']['memory_limit']
  end

  test 'should support directories without dirconfig' do
    assert_equal @extra_exercise.merged_config['root_config'], 'set'
  end
end

class ExerciseStubTest < ActiveSupport::TestCase
  setup do
    stub_all_activities!
    @exercise = create :exercise
  end

  test 'exercise should be valid and ok' do
    assert @exercise.valid?, 'Exercise was not valid'
    assert_equal @exercise.status, 'ok', 'Exercise was not ok'
  end
end
