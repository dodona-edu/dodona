class ReviewsController < ApplicationController
  before_action :set_series, only: %i[create_review review_create_wizard]
  before_action :set_review_session, only: %i[show edit update overview]
  before_action :set_review, only: %i[review review_complete]

  # GET /session/:id/review
  # Show the page with wizard to select the students
  def review_create_wizard
    return redirect_to review_session_path(@series.review_session) if @series.review_session

    @review_session = ReviewSession.new(series: @series)
    @review_session.deadline = @series.deadline
  end

  # POST /session/:id/review
  # Receive the data from the wizard and redirect towards the actual review session created
  def create_review
    return redirect_to review_session_path(@series.review_session) if @series.review_session

    params_sessions = params[:review_session]
    @review_session = ReviewSession.new(series: @series, deadline: params_sessions[:deadline])
    @review_session.with_lock do
      @review_session.transaction do
        if @review_session.save
          @series.review_session = @review_session
          @series.save
          @review_session.create_review_session(params_sessions[:exercises], params_sessions[:users])
          respond_to do |format|
            format.html { redirect_to review_session_path(@review_session) }
            format.json { render json: @series }
          end
        else
          respond_to do |format|
            format.html { render :review_create_wizard }
            format.json { render json: @review_session.errors, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  # GET /review_session/:id
  def show
    @reviews = @review_session.review_sheet
    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_session.show.review_session'), '#']]
  end

  # GET /review_session/:id/overview
  def overview
    submissions_current_user = @review_session.reviews.where(user: current_user)
    @reviewed_submissions = submissions_current_user.where.not(submission: nil)
    @unreviewed_submissions = submissions_current_user.where(submission: nil)

    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_session.overview.review_session'), '#']]
  end

  # GET /review_session/:id/edit
  def edit
    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_session.show.review_session'), '#']]
  end

  def update
    @review_session.with_lock do
      @review_session.transaction do
        @review_session.update_session(params)
        if @review_session.save
          respond_to do |format|
            format.html { redirect_to @review_session }
            format.json { render json: @review_session }
          end
        else
          respond_to do |format|
            format.html { redirect_to edit_review_session_path(@review_session), alert: I18n.t('review_session.edit.failure') }
            format.json { render json: @review_session.errors, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  def review
    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_session.show.review_session'), review_session_path(@review_session)], [I18n.t('reviews.show.review'), '#']]
  end

  def review_complete
    @review.completed = params[:review][:status]
    if @review.save
      respond_to do |format|
        format.html { redirect_to review_review_session_path(@review.review_session, @review) }
        format.json { render json: @review }
      end
    else
      respond_to do |format|
        format.html { redirect_to review_review_session_path(@review.review_session, @review), alert: I18n.t('review.completed.failure') }
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_series
    @series = Series.find(params[:id])
    authorize @series
  end

  def set_review_session
    @review_session = ReviewSession.find(params[:id])
    authorize @review_session
  end

  def set_review
    set_review_session
    @review = @review_session.reviews.find(params[:review_id])
    authorize @review
  end
end
