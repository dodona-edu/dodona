module EvaluationsHelper
  def feedback_action_button(text, other_feedback)
    if other_feedback
      link_to(evaluation_feedback_path(other_feedback.evaluation, other_feedback), class: 'feedback-nav-link') do
        button(text, false)
      end
    else
      button(text, true)
    end
  end

  private

  def button(text, disabled)
    button_tag(text, class: 'btn-text', disabled: disabled)
  end
end
