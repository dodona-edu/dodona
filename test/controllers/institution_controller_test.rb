require 'test_helper'

class InstitutionControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Institution, attrs: %i[name short_name]

  setup do
    @instance = institutions(:ugent)
    sign_in users(:zeus)
  end

  test_crud_actions only: %i[index show edit update], except: %i[update_redirect]

  test 'should be able to search by institution name' do
    i1 = create :institution, name: 'abcd'
    i2 = create :institution, name: 'efgh'

    get institutions_path, params: { filter: 'abcd' }

    assert_select 'a[href=?]', institution_path(i1), 1
    assert_select 'a[href=?]', institution_path(i2), 0
  end

  test 'should be able to edit provider mode' do
    create :provider, institution: @instance, mode: :prefer
    p2 = create :provider, institution: @instance, mode: :secondary
    put institution_path(@instance, { institution: { providers_attributes: [{ id: p2.id, mode: :redirect }] } })
    assert_redirected_to institutions_path
    assert p2.reload.redirect?
  end

  test 'should not be able to invalidly edit provider mode' do
    create :provider, institution: @instance, mode: :prefer
    p2 = create :provider, institution: @instance, mode: :secondary
    put institution_path(@instance, { institution: { providers_attributes: [{ id: p2.id, mode: :prefer }] } })
    assert_response :unprocessable_entity
    assert p2.reload.secondary?
  end

  test 'should render merge page' do
    get merge_institution_path(@instance)
    assert_response :success
    get merge_institution_path(@instance, format: :js), xhr: true
    assert_response :success
  end

  test 'should render merge_changes js' do
    other = create :institution
    create :provider, institution: @instance, mode: :prefer
    get merge_changes_institution_path(@instance, other_institution_id: other.id, format: :js), xhr: true
    assert_response :success
  end

  test 'should do merge' do
    other = create :institution
    post merge_institution_path(@instance, other_institution_id: other.id)
    assert_redirected_to institution_path(other)
    assert_not Institution.exists?(id: @instance.id)
  end

  test 'should not merge if there are overlapping usernames' do
    create :provider, institution: @instance, mode: :prefer
    user = create :user, institution: @instance
    institution = create :institution
    create :user, institution: institution, username: user.username
    post merge_institution_path(@instance, other_institution_id: institution.id)
    assert_response :unprocessable_entity
  end
end
