class LabelsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Label, attrs: %i[name]

  def setup
    @instance = create :label
    sign_in create :zeus
  end

  test_crud_actions
end
