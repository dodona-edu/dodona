class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[update destroy]

  def index
    authorize Notification
    @title = I18n.t('notifications.index.title')
    @notifications = current_user.notifications.paginate(page: parse_pagination_param(params[:page]), per_page: parse_pagination_param(params[:per_page]))
    @unread_notifications = @notifications.any? ? current_user.notifications.where(read: false).to_a : []
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
    end
  end

  def destroy_all
    authorize Notification
    notifications = Notification.where(user: current_user)
    notifications.destroy_all
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to controller: 'pages', action: 'home' }
    end
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
    authorize @notification
  end
end
