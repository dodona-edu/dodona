class ProgrammingLanguagesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers ProgrammingLanguage, attrs: %i[name editor_name renderer_name extension]

  def setup
    @instance = create :programming_language
    sign_in create :zeus
  end

  test_crud_actions
end
