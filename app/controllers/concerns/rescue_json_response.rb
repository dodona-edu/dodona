module RescueJsonResponse
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid do |exception|
      raise unless request.format.json?

      render json: exception.record.errors, status: :unprocessable_entity
    end
  end
end
