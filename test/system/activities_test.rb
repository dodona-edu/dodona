require 'capybara/minitest'
require 'application_system_test_case'

class ActivitiesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @instance = exercises(:python_exercise)
    @user = users(:zeus)
    sign_in @user
  end

  test 'should show exercise' do
    visit exercise_path(id: @instance.id)
    assert_text @instance.name_en
  end

  test 'should show boilerplate in code editor' do
    @instance.stubs(:boilerplate).returns('boilerplate') do
      visit exercise_path(id: @instance.id)
      assert_text 'boilerplate'
    end
  end

  test 'show latest submission in code editor' do
    create :submission, exercise: @instance, user: @user, status: :correct, code: 'print("hello")'
    visit exercise_path(id: @instance.id)
    assert_text 'print("hello")'
  end

  test 'should show message to clear editor if latest submission is shown' do
    create :submission, exercise: @instance, user: @user, status: :correct, code: 'print("hello")'
    visit exercise_path(id: @instance.id)
    assert_text 'Clear editor'
  end

  test 'should show message to restore boilerplate if latest submission is shown' do
    Exercise.any_instance.stubs(:boilerplate).returns('boilerplate')
    create :submission, exercise: @instance, user: @user, status: :correct, code: 'print("hello")'
    visit exercise_path(id: @instance.id)
    assert_text 'Restore the initial code.'
    find('a', text: 'Restore the initial code.').click
    assert_text 'boilerplate'
  end

  test 'should not break on complex unicode characters' do
    Exercise.any_instance.stubs(:boilerplate).returns('`<script>alert("😀")</script>`')
    visit exercise_path(id: @instance.id)
    assert_text '`<script>alert("😀")</script>`'

    create :submission, exercise: @instance, user: @user, status: :correct, code: 'print("😀")'
    visit exercise_path(id: @instance.id)
    assert_text 'print("😀")'
    assert_text 'Restore the initial code.'
    find('a', text: 'Restore the initial code.').click
    assert_text '`<script>alert("😀")</script>`'
  end
end
