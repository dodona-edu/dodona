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
        annotation_text: "We changed this text"
      }
    }
    assert_response :success

    patch "/submissions/#{@submission.id}/annotations/#{@annotation.id}", params: {
      annotation: {
        annotation_text: "We changed this text again"
      }
    }
    assert_response :success

    # TODO: Fix this behaviour as it does allow an annotation to change line_nr
    # Reason: Unpermitted parameters do not trigger an exception
    # put "/submissions/#{@submission.id}/annotations/#{@annotation.id}", params: {
    #   annotation: {
    #     annotation_text: "We changed this text, but also the line nr",
    #     line_nr: 1
    #   }
    # }
    # assert_response :unauthorized

  end

  test 'can remove annotation' do
    @annotation = create :annotation, submission: @submission, user: @zeus
    delete "/submissions/#{@submission.id}/annotations/#{@annotation.id}"
    assert_response :no_content
  end
end
