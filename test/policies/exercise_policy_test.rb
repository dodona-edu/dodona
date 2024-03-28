require 'test_helper'

class ExercisePolicyTest < ActiveSupport::TestCase
  def test_scope; end

  def test_show; end

  def test_create; end

  def test_update; end

  def test_destroy; end

  test 'permitted_attributes should return empty list because status is not ok ' do
    policy = ExercisePolicy.new(create(:temporary_user), create(:exercise))

    assert_empty policy.permitted_attributes
  end

  test 'permitted_attributes should return empty list because user is not repository admin' do
    policy = ExercisePolicy.new(create(:temporary_user), create(:exercise, :valid))

    assert_empty policy.permitted_attributes
  end

  test 'permitted_attributes should return something because exercise is valid and user is repository admin' do
    policy = ExercisePolicy.new(create(:temporary_user), create(:exercise, :valid))
    User.any_instance.stubs(:repository_admin?).returns(true)

    assert_equal %i[access name_nl name_en], policy.permitted_attributes
  end
end
