require 'test_helper'

require 'helpers/crud_helper'

class JudgesControllerTest < ActionDispatch::IntegrationTest
  JUDGE_ATTRS = %i[name image renderer runner remote]
  extend CRUDTest

  setup do
    stub_git(Judge.any_instance)
    @judge = create :judge
    sign_in create(:zeus)
  end

  crud_tests Judge


  def allowed_attrs
    %i[name image renderer runner remote]
  end

  def model
    Judge
  end

  test 'should get index' do
    get judges_url
    assert_response :success
  end

  test 'should get new' do
    get new_judge_url
    assert_response :success
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
    produces_object_with_attributes do |attrs|
      patch judge_url(@judge), model_params(attrs)
      assert_redirected_to judge_url(@judge)
      @judge.reload
    end
  end


  test 'should destroy judge' do
    assert_difference(-> { Judge.count }, -1) do
      delete judge_url(@judge)
    end

    assert_redirected_to judges_url
  end
end
