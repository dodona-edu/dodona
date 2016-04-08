class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update_exercises
    response = Exercise.refresh
    message = response[1]
    status = response[0] == 0 ? 200 : 500
    render plain: message, status: status
  end
end
