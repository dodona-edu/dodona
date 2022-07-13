require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test 'should get homepage' do
    get root_url
    assert_response :success
  end

  test 'should get homepage as json' do
    get root_url(format: :json)
    assert_response :success
  end

  test 'should get signed in homepage' do
    sign_in(users(:student))
    get root_url
    assert_response :success
  end

  test 'should get signed in homepage when user submitted to content page' do
    user = users(:student)
    activity = create :exercise
    create :submission,
           user: user,
           exercise: activity
    activity.update(type: ContentPage.name)

    sign_in(user)
    get root_url
    assert_response :success
  end

  test 'should get contact page' do
    get contact_url
    assert_response :success
  end

  test 'should send email' do
    contact_form = {
      name: 'Jan',
      email: 'Jan@UGent.BE',
      subject: '(╯°□°）╯︵ ┻━┻)',
      message: '┬─┬ノ( º _ ºノ )'
    }
    assert_changes 'ActionMailer::Base.deliveries.size', +1 do
      post create_contact_path(contact_form: contact_form)
    end
    assert_redirected_to root_url
  end

  test 'should get profile when logged in' do
    user = users(:student)
    sign_in user
    get profile_url
    assert_response :redirect
    assert_redirected_to user_path(user)
  end

  test 'should not get profile when logged out' do
    get profile_url
    assert_response :redirect
    assert_redirected_to sign_in_url
  end

  test 'should get support us page' do
    get support_us_url
    assert_response :success
  end

  test 'should get about page' do
    get about_url
    assert_response :success
  end

  test 'should redirect to privacy_prompt if user has not accepted_privacy_policy' do
    user = create :user, accepted_privacy_policy: false
    sign_in(user)
    [root_url, courses_url, submissions_url, profile_url, questions_url].each do |url|
      get url
      assert_redirected_to privacy_prompt_path
    end
  end

  test 'After accepting privacy policy, should redirect back to original target' do
    [root_url, courses_url, submissions_url, profile_url, questions_url].each do |url|
      url = url.chomp('/')
      user = create :user, accepted_privacy_policy: false
      sign_in(user)
      get url
      assert_redirected_to privacy_prompt_path
      post privacy_prompt_path
      assert_redirected_to url
    end
  end

  test 'After accepting privacy policy, should redirect back to root if no original target' do
    user = create :user, accepted_privacy_policy: false
    sign_in(user)
    get privacy_prompt_path
    assert_response :success
    post privacy_prompt_path
    assert_redirected_to root_url
  end

  test 'should not redirect from info pages to privacy_prompt if user has not accepted_privacy_policy' do
    user = create :user, accepted_privacy_policy: false
    sign_in(user)
    [about_url, privacy_url, data_url, contact_url, support_us_url].each do |url|
      get url
      assert_response :success
    end
  end
end
