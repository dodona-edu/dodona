class AnnouncementsController < ApplicationController
  protect_from_forgery except: :index

  has_scope :unread, as: 'unread', type: :boolean do |controller, scope|
    scope.unread_by(controller.current_user)
  end

  def index
    authorize Announcement
    @announcements = apply_scopes(policy_scope(Announcement.all))
  end

  def mark_as_read
    authorize Announcement
    announcement = Announcement.find(params[:id].to_i)
    respond_to do |format|
      if announcement
        if AnnouncementView.where(user_id: current_user.id, announcement_id: announcement.id).first_or_create(user_id: current_user.id, announcement_id: announcement.id)
          format.json { render json: :ok }
          format.js { redirect_to action: :index, unread: true }
        else
          format.json { render json: nil, status: :unprocessable_entity }
        end
      else
        format.json { render json: nil, status: :unprocessable_entity }
      end
    end
  end

  def new
    authorize Announcement
    @announcement = Announcement.new
  end

  def create
    authorize Announcement
    @announcement = Announcement.new(permitted_attributes(Announcement))
    if @announcement.save
      redirect_to action: :index
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @annotation.destroy
    render json: {}, status: :no_content
  end
end
