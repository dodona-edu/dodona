require "application_system_test_case"

class AnnotationsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit root_url
    assert_text "Dodona"
  end
end
