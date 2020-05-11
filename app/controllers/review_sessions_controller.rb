class ReviewSessionsController < ApplicationController
  before_action :set_review_session, only: %i[show edit update destroy]
  before_action :set_series, only: %i[new]

  def show
    @reviews = @review_session.review_sheet
    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_sessions.show.review_session'), '#']]
  end

  def new
    if @series.review_session.present?
      redirect_to review_session_path(@series.review_session)
      return
    end
    @review_session = ReviewSession.new(series: @series, deadline: @series.deadline)
    authorize @review_session
  end

  def edit
    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_session.edit.title'), '#']]
  end

  def create
    @review_session = ReviewSession.new(permitted_attributes(ReviewSession))
    authorize @review_session
    @review_session.users = @review_session.series.course.enrolled_members
    @review_session.exercises = @review_session.series.exercises

    respond_to do |format|
      if @review_session.save
        format.html { redirect_to review_session_path(@review_session) }
        format.json { render :show, status: :created, location: @review_session }
      else
        format.html { render :new }
        format.json { render json: @review_session.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @review_session.update(permitted_attributes(@review_session))
        format.html { redirect_to review_session_path(@review_session), notice: I18n.t('controllers.updated', model: ReviewSession.model_name.human) }
        format.json { render :show, status: :ok, location: @review_session }
      else
        format.html { render :edit }
        format.json { render json: @review_session.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @review_session.destroy
    respond_to do |format|
      format.html { redirect_to course_url(@review_session.series.course, anchor: @review_session.series.anchor), notice: I18n.t('controllers.destroyed', model: ReviewSession.model_name.human) }
      format.json { head :no_content }
    end
  end

  private

  def set_review_session
    @review_session = ReviewSession.find(params[:id])
    authorize @review_session
  end

  def set_series
    @series = Series.find(params[:series_id])
  end
end
