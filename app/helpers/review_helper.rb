module ReviewHelper
  def review_action_button(translation, other_review)
    if other_review
      route = review_review_session_path(other_review.review_session, other_review)

      return ActionController::Base.helpers.link_to(route) do
        button(translation, false)
      end
    end
    ActionController::Base.helpers.link_to('#') do
      button(translation, true)
    end
  end

  private

  def button(trans, disabled)
    ActionController::Base.helpers.button_tag(I18n.t(trans), class: 'btn btn-default btn-text', disabled: disabled)
  end
end
