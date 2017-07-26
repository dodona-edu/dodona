require 'test_helper'

require 'helpers/crud_helper'

class JudgesControllerTest < ActionDispatch::IntegrationTest
  JUDGE_ATTRS = %i[name image renderer runner remote]
  extend CRUDTest

  setup do
    stub_git(Judge.any_instance)
    @instance = create :judge
    sign_in create(:zeus)
  end

  crud_tests Judge


  def allowed_attrs
    %i[name image renderer runner remote]
  end

  def model
    Judge
  end

  test 'should destroy judge' do
    assert_difference(-> { Judge.count }, -1) do
      delete judge_url(@judge)
    end

    assert_redirected_to judges_url
  end
end
