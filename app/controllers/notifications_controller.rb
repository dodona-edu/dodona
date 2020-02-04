class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[update destroy]

  def index
    @notifications = Notification.all
  end

  def update
    respond_to do |format|
      if @notification.update(permitted_attributes(@notification))
        format.json { render :show, status: :ok, location: @notification }
      else
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @notification.destroy
    respond_to do |format|
      format.json { head :no_content }
      format.js
    end
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
    authorize @notification
  end
end
