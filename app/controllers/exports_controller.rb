class ExportsController < ApplicationController
  include SeriesHelper

  before_action :set_user,
                only: %i[new_series_export new_course_export create_series_export create_course_export]

  def show
    @export = Export.find(params[:id])
    authorize @export
    respond_to do |format|
      format.json
      format.any(:zip, :html) do
        if @export.finished? && @export.archive.attached?
          redirect_to rails_blob_path(@export.archive, disposition: 'attachment')
        else
          head :not_found
        end
      end
    end
  end

  def new_series_export
    @series = Series.find(params[:id])
    authorize @series, :export?
    authorize @user, :export? if @user
    @crumbs = [[@series.course.name, course_path(@series.course)], [@series.name, breadcrumb_series_path(@series, current_user)], [I18n.t('exports.download_submissions.title'), '#']]
    @data = { item: @series,
              users: ([@user] if @user),
              list: @series.exercises,
              course: @series.course,
              choose_step_text: t('exports.download_submissions.choose_exercises'),
              table_header_type: t('exports.download_submissions.exercise'),
              is_series?: true }
    render 'download_submissions'
  end

  def new_course_export
    @course = Course.find(params[:id])
    authorize @course, :export?
    authorize @user, :export? if @user
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('exports.download_submissions.title'), '#']]
    @data = { item: @course,
              users: ([@user] if @user),
              list: policy_scope(@course.series),
              choose_step_text: t('exports.download_submissions.choose_series'),
              table_header_type: t('exports.download_submissions.series') }
    render 'download_submissions'
  end

  def new_user_export
    @user = User.find(params[:id])
    authorize @user, :export?
    @crumbs = [[@user.full_name, user_path(@user)], [I18n.t('exports.download_submissions.title'), '#']]
    @data = { item: @user,
              list: @user.courses,
              choose_step_text: t('exports.download_submissions.choose_courses'),
              table_header_type: t('exports.download_submissions.course') }
    render 'download_submissions'
  end

  def create_series_export
    item = Series.find(params[:id])
    list = Exercise.where(id: params[:selected_ids])
    create(item, list)
  end

  def create_course_export
    item = Course.find(params[:id])
    list = Series.where(id: params[:selected_ids])
    create(item, list)
  end

  def create_user_export
    item = User.find(params[:id])
    list = Course.where(id: params[:selected_ids])
    create(item, list)
  end

  private

  def set_user
    @user = User.find(params[:user_id]) if params[:user_id].present?
  end

  def create(item, list)
    authorize item, :export?
    authorize @user, :export? if @user

    if @user.blank? && (item.instance_of?(Series) || item.instance_of?(Course))
      authorize item, :course_admin?
      params[:with_labels] = true
    else
      # only course admins should be able to export labels
      params.delete(:with_labels)
    end

    # Only retain supported options from the received function parameters
    options = params.permit(Export::Zipper::SUPPORTED_OPTIONS)

    export = Export.create(user: current_user)
    export.delay(queue: 'exports').start(item, list, ([@user] if @user), options)
    respond_to do |format|
      format.json { render json: { url: export_path(export) } }
    end
  end
end
