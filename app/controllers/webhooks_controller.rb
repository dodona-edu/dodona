class WebhooksController < ApplicationController
  def update_exercises
    response = Exercise.refresh
    message = response[1]
    status = response[0] == 0 ? 200 : 500
    render plain: message, status: status
  end
end
