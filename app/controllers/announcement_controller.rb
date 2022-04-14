class AnnouncementController < ApplicationController


  def index
    authorize Announcement
    @announcements = apply_scopes(policy_scope(Annotation.all))
  end

  def mark_as_read
    authorize Announcement
    announcement = Announcement.find(params[:id].to_i)
    respond_to do |format|
      if announcement
        if AnnouncementView.where(user_id: current_user.id, announcement_id: announcement.id).first_or_create(user_id: current_user.id, announcement_id: announcement.id)
          format.json { render json: :ok }
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
    @title = I18n.t('announcements.new.title')
    @announcement = Announcement.new
  end

  def create
    authorize Announcement
    @announcement = Announcement.new(permitted_attributes(Announcement))
    respond_to do |format|
      if @announcement.save
        format.json { render :show, status: :created, location: @announcement }
      else
        format.json { render json: @announcement.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @annotation.destroy
    render json: {}, status: :no_content
  end
end
