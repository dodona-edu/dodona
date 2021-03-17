require 'test_helper'

class InstitutionControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Institution, attrs: %i[name short_name]

  setup do
    @instance = create(:institution)
    sign_in create(:zeus)
  end

  test_crud_actions only: %i[index show edit update], except: %i[update_redirect]

  test 'should be able to search by institution name' do
    i1 = create :institution, name: 'abcd'
    i2 = create :institution, name: 'efgh'

    get institutions_path, params: { filter: 'abcd' }

    assert_select 'a[href=?]', institution_path(i1), 1
    assert_select 'a[href=?]', institution_path(i2), 0
  end
end
