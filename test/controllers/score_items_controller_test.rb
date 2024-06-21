require 'test_helper'

class ScoreItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = users(:staff)
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
  end

  test 'should copy score items if course administrator' do
    from = @evaluation.evaluation_exercises.first
    create :score_item, evaluation_exercise: from
    create :score_item, evaluation_exercise: from

    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      to = create :evaluation_exercise, evaluation: @evaluation
      sign_in user if user.present?
      post copy_evaluation_score_items_path(@evaluation, format: :js), params: {
        copy: {
          from: from.id,
          to: to.id
        }
      }

      assert_response expected
      assert_equal 2, to.score_items.count if expected == :success

      sign_out user if user.present?
    end
  end

  test 'should add score items to all if course administrator' do
    [
      [@staff_member, :ok],
      [users(:student), :no],
      [create(:staff), :no],
      [users(:zeus), :ok],
      [nil, :no]
    ].each do |user, expected|
      sign_in user if user.present?
      post add_all_evaluation_score_items_path(@evaluation, format: :js), params: {
        score_item: {
          name: 'Test',
          description: 'Test',
          maximum: '20.0'
        }
      }
      @evaluation.evaluation_exercises.reload
      @evaluation.evaluation_exercises.each do |e|
        if expected == :ok
          assert_equal 1, e.score_items.length
          e.update!(score_items: [])
        end

        assert_empty e.score_items
      end
      sign_out user if user.present?
    end
  end

  test 'should update score item if course administrator' do
    exercise = @evaluation.evaluation_exercises.first
    score_item = create :score_item, evaluation_exercise: exercise,
                                     description: 'Before test',
                                     maximum: '10.0'

    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      patch evaluation_score_item_path(@evaluation, score_item, format: :json), params: {
        score_item: {
          description: 'After test',
          maximum: '20.0'
        }
      }

      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'should create score item if course administrator' do
    [
      [@staff_member, :created],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :created],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      post evaluation_score_items_path(@evaluation, format: :json), params: {
        score_item: {
          name: 'Code re-use',
          description: 'After test',
          maximum: '10.0',
          evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
        }
      }

      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'should not create score item for invalid data' do
    # Missing data
    post evaluation_score_items_path(@evaluation, format: :json), params: {
      score_item: {
        name: 'Code re-use',
        evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
      }
    }

    assert_response :unprocessable_entity

    # Negative maximum
    post evaluation_score_items_path(@evaluation, format: :json), params: {
      score_item: {
        name: 'Code re-use',
        maximum: '-20.0',
        evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
      }
    }

    assert_response :unprocessable_entity
  end

  test 'should not update score item for invalid data' do
    score_item = create :score_item, evaluation_exercise: @evaluation.evaluation_exercises.sample
    # Negative maximum
    patch evaluation_score_item_path(@evaluation, score_item, format: :json), params: {
      score_item: {
        maximum: '-20.0'
      }
    }

    assert_response :unprocessable_entity
  end

  test 'should delete score item if course administrator' do
    exercise = @evaluation.evaluation_exercises.first

    assert_equal 0, exercise.score_items.count

    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      score_item = create :score_item, evaluation_exercise: exercise,
                                       description: 'Code re-use',
                                       maximum: '10.0'

      assert_equal 1, exercise.score_items.count
      sign_in user if user.present?
      delete evaluation_score_item_path(@evaluation, score_item, format: :json)

      assert_response expected
      exercise.score_items.reload
      assert_equal 0, exercise.score_items.count if response == :success

      sign_out user if user.present?
      exercise.update!(score_items: [])
    end
  end

  test 'should be able to download score items as CSV' do
    exercise = @evaluation.evaluation_exercises.first
    create :score_item, evaluation_exercise: exercise, name: 'foo', maximum: 10.0, description: 'bar'
    create :score_item, evaluation_exercise: exercise, name: 'baz', maximum: 20.0, description: 'qux', visible: false

    get evaluation_evaluation_exercise_score_items_path(@evaluation, exercise, format: :csv)

    assert_response :success

    csv = CSV.parse(response.body, headers: true)

    assert_equal 2, csv.length
    assert_equal %w[name maximum description visible], csv.headers
    assert_equal %w[foo 10.0 bar true], csv[0].fields
    assert_equal %w[baz 20.0 qux false], csv[1].fields
  end

  test 'should be able to upload score items as CSV' do
    exercise = @evaluation.evaluation_exercises.first

    assert_equal 0, exercise.score_items.count

    file = Tempfile.new
    file.write("name,maximum,description,visible\n")
    file.write("foo,10.0,bar,true\n")
    file.write("baz,20.0,qux,false\n")
    file.close

    post upload_evaluation_evaluation_exercise_score_items_path(@evaluation, exercise, format: :json), params: {
      upload: {
        file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
      }
    }

    assert_response :no_content
    exercise.reload

    assert_equal 2, exercise.score_items.count
    assert_equal 'foo', exercise.score_items[0].name
    assert_in_delta(10.0, exercise.score_items[0].maximum)
    assert_equal 'bar', exercise.score_items[0].description
    assert exercise.score_items[0].visible
    assert_equal 'baz', exercise.score_items[1].name
    assert_in_delta(20.0, exercise.score_items[1].maximum)
    assert_equal 'qux', exercise.score_items[1].description
    assert_not exercise.score_items[1].visible
  end

  test 'should be able to upload with only name and maximum' do
    exercise = @evaluation.evaluation_exercises.first

    assert_equal 0, exercise.score_items.count

    file = Tempfile.new
    file.write("name,maximum\n")
    file.write("foo,10.0\n")
    file.write("baz,20.0\n")
    file.close

    post upload_evaluation_evaluation_exercise_score_items_path(@evaluation, exercise, format: :json), params: {
      upload: {
        file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
      }
    }

    assert_response :success

    exercise.reload

    assert_equal 2, exercise.score_items.count
    assert_equal 'foo', exercise.score_items[0].name
    assert_in_delta(10.0, exercise.score_items[0].maximum)
    assert_nil exercise.score_items[0].description
    assert exercise.score_items[0].visible
    assert_equal 'baz', exercise.score_items[1].name
    assert_in_delta(20.0, exercise.score_items[1].maximum)
    assert_nil exercise.score_items[1].description
    assert exercise.score_items[1].visible
  end

  test 'should not upload without name or maximum' do
    exercise = @evaluation.evaluation_exercises.first

    assert_equal 0, exercise.score_items.count

    file = Tempfile.new
    file.write("name,maximum\n")
    file.write("foo,10.0\n")
    file.write(",20.0\n")
    file.close

    post upload_evaluation_evaluation_exercise_score_items_path(@evaluation, exercise, format: :json), params: {
      upload: {
        file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
      }
    }

    assert_response :unprocessable_entity

    exercise.reload

    assert_equal 0, exercise.score_items.count
  end

  test 'should replace score items if uploading again' do
    exercise = @evaluation.evaluation_exercises.first
    create :score_item, evaluation_exercise: exercise, name: 'foo', maximum: 10.0, description: 'bar'

    assert_equal 1, exercise.score_items.count

    file = Tempfile.new
    file.write("name,maximum,description,visible\n")
    file.write("baz,20.0,qux,false\n")
    file.close

    post upload_evaluation_evaluation_exercise_score_items_path(@evaluation, exercise, format: :json), params: {
      upload: {
        file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
      }
    }

    assert_response :no_content

    exercise.reload

    assert_equal 1, exercise.score_items.count
    assert_equal 'baz', exercise.score_items[0].name
    assert_in_delta(20.0, exercise.score_items[0].maximum)
    assert_equal 'qux', exercise.score_items[0].description
    assert_not exercise.score_items[0].visible
  end

  test 'Should not replace score items if uploading invalid data' do
    exercise = @evaluation.evaluation_exercises.first
    create :score_item, evaluation_exercise: exercise, name: 'foo', maximum: 10.0, description: 'bar'

    assert_equal 1, exercise.score_items.count

    file = Tempfile.new
    file.write("name,maximum,description,visible\n")
    file.write("baz,-20.0,qux,false\n")
    file.close

    post upload_evaluation_evaluation_exercise_score_items_path(@evaluation, exercise, format: :json), params: {
      upload: {
        file: Rack::Test::UploadedFile.new(file.path, 'text/csv')
      }
    }

    assert_response :unprocessable_entity

    exercise.reload

    assert_equal 1, exercise.score_items.count
    assert_equal 'foo', exercise.score_items[0].name
    assert_in_delta(10.0, exercise.score_items[0].maximum)
    assert_equal 'bar', exercise.score_items[0].description
    assert exercise.score_items[0].visible
  end
end
