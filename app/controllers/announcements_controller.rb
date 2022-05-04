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
          format.js { render :mark_as_read }
        else
          format.json { render json: nil, status: :unprocessable_entity }
        end
      else
        format.json { render json: nil, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize Announcement
    @announcement = Announcement.find(params[:id])
    authorize @announcement
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

  def update
    authorize Announcement
    @announcement = Announcement.find(params[:id])
    authorize @announcement
    if @announcement.update(permitted_attributes(@announcement))
      redirect_to action: :index
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Announcement.destroy(params[:id])
    redirect_to action: :index
  end
end
