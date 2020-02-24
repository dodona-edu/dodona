require 'test_helper'

class AnnotationControllerTest < ActionDispatch::IntegrationTest
  def setup
    @submission = create :correct_submission
    @zeus = create(:zeus)
    sign_in @zeus
  end

  test 'can create annotation' do
    post "/submissions/#{@submission.id}/annotations", params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Not available'
      }
    }

    assert_response :created
  end

  test 'can update annotation, but only the content' do
    @annotation = create :annotation, submission: @submission, user: @zeus

    put "/submissions/#{@submission.id}/annotations/#{@annotation.id}", params: {
      annotation: {
        annotation_text: 'We changed this text'
      }
    }
    assert_response :success

    patch "/submissions/#{@submission.id}/annotations/#{@annotation.id}", params: {
      annotation: {
        annotation_text: 'We changed this text again'
      }
    }
    assert_response :success
  end

  test 'can remove annotation' do
    @annotation = create :annotation, submission: @submission, user: @zeus
    delete "/submissions/#{@submission.id}/annotations/#{@annotation.id}"
    assert_response :no_content
  end

  test 'can not create invalid annotation' do
    post "/submissions/#{@submission.id}/annotations", params: {
      annotation: {
        line_nr: 1_500_000_000,
        annotation_text: 'You shall not pass'
      }
    }
    assert_response :unprocessable_entity
  end

  test 'can not update valid annotation with invalid annotation' do
    @annotation = create :annotation, submission: @submission, user: @zeus

    put "/submissions/#{@submission.id}/annotations/#{@annotation.id}", params: {
      annotation: {
        # Titanic script is around 4500 sentences worth of text, so why not test that users can not submit such long content
        annotation_text: Faker::Lorem.sentences(number: 4_500).join(' ')
      }
    }

    assert_response :unprocessable_entity
  end

  test 'can query the index of all annotations on a submission' do
    create :annotation, submission: @submission, user: @zeus
    create :annotation, submission: @submission, user: @zeus
    create :annotation, submission: @submission, user: @zeus

    get "/submissions/#{@submission.id}/annotations", params: { format: :json }

    assert_response :ok
  end
end
