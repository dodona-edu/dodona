require 'test_helper'

class JudgesControllerTest < ActionDispatch::IntegrationTest
  JUDGE_ATTRS = %i[name image renderer runner remote]

  setup do
    sign_in create(:user, permission: :zeus)
    stub_git(Judge.any_instance)
    @judge = create :judge
  end

  test 'should get index' do
    get judges_url
    assert_response :success
  end

  test 'should get new' do
    get new_judge_url
    assert_response :success
  end

  test 'should create judge' do
    attrs = attributes_for(:judge).slice(*JUDGE_ATTRS)
    assert_difference(-> { Judge.count }) do
      post judges_url,
           params: {
             judge: attrs
           }
    end

    judge = Judge.last
    attrs.each do |attr, value|
      assert_equal value, judge.send(attr)
    end
    assert_redirected_to judge_url(judge)
  end

  test 'should show judge' do
    get judge_url(@judge)
    assert_response :success
  end

  test 'should get edit' do
    get edit_judge_url @judge
    assert_response :success
  end

  test 'should update judge' do
    attrs = attributes_for(:judge).slice(*JUDGE_ATTRS)
    patch judge_url(@judge),
          params: {
            judge: attrs
          }
    assert_redirected_to judge_url(@judge)

    @judge.reload
    attrs.each do |attr, value|
      assert_equal value, @judge.send(attr)
    end
  end


  test 'should destroy judge' do
    assert_difference(-> { Judge.count }, -1) do
      delete judge_url(@judge)
    end

    assert_redirected_to judges_url
  end
end
