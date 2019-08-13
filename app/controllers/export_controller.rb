class ExportController < ApplicationController
  before_action :set_user,
                except: %i[download_submissions_from_user start_download_from_user]
  # GET export/series/x
  def download_submissions_from_series
    @series = Series.find(params[:id])
    @export = Export.new(item: @series, users: ([@user] if @user))
    authorize(@export)
    @crumbs = [[@series.course.name, course_path(@series.course)], [@series.name, series_path(@series)]]
    @data = { list: @series.exercises,
              course: @series.course,
              summary: SeriesSummary.new(user: @user || current_user, series: @series, exercises: @series.exercises),
              choose_step_text: t('export.download_submissions.choose_exercises'),
              table_header_type: t('export.download_submissions.exercise'),
              is_series?: true }
    render 'download_submissions'
  end

  # GET export/courses/x
  def download_submissions_from_course
    @course = Course.find(params[:id])
    @export = Export.new(item: @course, users: ([@user] if @user))
    authorize(@export)
    @crumbs = [[@course.name, course_path(@course)]]
    @data = { list: policy_scope(@course.series),
              choose_step_text: t('export.download_submissions.choose_series'),
              table_header_type: t('export.download_submissions.series') }
    render 'download_submissions'
  end

  # GET export/users/x
  def download_submissions_from_user
    @user = User.find(params[:id])
    @export = Export.new(item: @user)
    authorize(@export)
    @crumbs = [[@user.full_name, user_path(@user)]]
    @data = { list: @user.courses,
              choose_step_text: t('export.download_submissions.choose_courses'),
              table_header_type: t('export.download_submissions.course') }
    render 'download_submissions'
  end

  # POST export/series/x
  def start_download_from_series
    start_download Series, Exercise
  end

  # POST export/courses/x
  def start_download_from_course
    start_download Course, Series
  end

  # POST export/users/x
  def start_download_from_user
    start_download User, Course
  end

  private

  def set_user
    @user = User.find(params[:user_id]) if params[:user_id].present?
  end

  def start_download(item_model, list_model)
    evaluate_export Export.new(
      item: item_model.find(params[:id]),
      users: ([@user] unless @user.nil?),
      list: list_model.where(id: params[:selected_ids]),
      options: params
    )
  end

  def evaluate_export(export)
    authorize export
    if export.valid?
      send_zip export.bundle
    else
      render json: { status: 'failed', errors: export.errors }, status: :bad_request
    end
  end
end
