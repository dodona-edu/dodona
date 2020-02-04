class ExportsController < ApplicationController
  before_action :set_user,
                only: %i[new_for_course new_for_series create_for_series create_for_course]

  def index
    authorize Export
    @title = I18n.t('exports.index.title')
    @exports = policy_scope(Export)
  end

  def new_for_series
    @series = Series.find(params[:id])
    authorize @series, :export?
    authorize @user, :export? if @user
    @crumbs = [[@series.course.name, course_path(@series.course)], [@series.name, series_path(@series)], [I18n.t('exports.download_submissions.title'), '#']]
    @data = { item: @series,
              users: ([@user] if @user),
              list: @series.exercises,
              course: @series.course,
              summary: SeriesSummary.new(user: @user || current_user, series: @series, exercises: @series.exercises),
              choose_step_text: t('exports.download_submissions.choose_exercises'),
              table_header_type: t('exports.download_submissions.exercise'),
              is_series?: true }
    render 'download_submissions'
  end

  def new_for_course
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

  def new_for_user
    @user = User.find(params[:id])
    authorize @user, :export?
    @crumbs = [[@user.full_name, user_path(@user)], [I18n.t('exports.download_submissions.title'), '#']]
    @data = { item: @user,
              list: @user.courses,
              choose_step_text: t('exports.download_submissions.choose_courses'),
              table_header_type: t('exports.download_submissions.course') }
    render 'download_submissions'
  end

  def create_for_series
    item = Series.find(params[:id])
    list = Exercise.where(id: params[:selected_ids])
    create(item, list)
  end

  def create_for_course
    item = Course.find(params[:id])
    list = Series.where(id: params[:selected_ids])
    create(item, list)
  end

  def create_for_user
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

    Export.create(user: current_user).delay(queue: 'exports').start(item, list, ([@user] if @user), params)
    redirect_to action: 'index'
  end
end
