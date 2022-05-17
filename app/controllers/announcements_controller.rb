class AnnouncementsController < ApplicationController
  protect_from_forgery except: :index
  before_action :set_announcement, except: %i[index new create]

  has_scope :unread, as: 'unread', type: :boolean do |controller, scope|
    scope.unread_by(controller.current_user)
  end

  def index
    authorize Announcement
    @announcements = apply_scopes(policy_scope(Announcement.all))
    @title = I18n.t('announcements.index.title')
    @crumbs = [[I18n.t('announcements.index.title'), '#']]
  end

  def mark_as_read
    if announcement.present? && AnnouncementView.where(user_id: current_user.id, announcement_id: announcement.id).first_or_create(user_id: current_user.id, announcement_id: announcement.id)
      render :mark_as_read
    else
      render js: nil, status: :unprocessable_entity
    end
  end

  def edit
    @title = I18n.t('announcements.edit.title')
    @crumbs = [[I18n.t('announcements.index.title'), labels_path], [I18n.t('announcements.edit.title'), '#']]
  end

  def new
    authorize Announcement
    @announcement = Announcement.new
    @title = I18n.t('announcements.new.title')
    @crumbs = [[I18n.t('announcements.index.title'), labels_path], [I18n.t('announcements.new.title'), '#']]
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

  def set_announcement
    @announcement = Announcement.find(params[:id])
    authorize @announcement
  end
end
