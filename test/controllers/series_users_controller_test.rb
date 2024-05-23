require "test_helper"

class SeriesUsersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get series_users_index_url
    assert_response :success
  end

  test "should get create" do
    get series_users_create_url
    assert_response :success
  end

  test "should get destroy" do
    get series_users_destroy_url
    assert_response :success
  end

  test "should get destroy_all" do
    get series_users_destroy_all_url
    assert_response :success
  end
end
