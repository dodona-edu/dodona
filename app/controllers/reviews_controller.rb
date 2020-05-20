class ReviewsController < ApplicationController
  include SeriesHelper

  before_action :set_review, only: %i[show edit update]

  has_scope :by_filter, as: 'filter' do |_controller, scope, value|
    scope.by_filter(value, true, true)
  end

  has_scope :by_status, as: 'status'

  def show
    @auto_mark = params[:auto_mark]
    @crumbs = [
      [@review.review_session.series.course.name, course_url(@review.review_session.series.course)],
      [@review.review_session.series.name, breadcrumb_series_path(@review.review_session.series, current_user)],
      [I18n.t('review_sessions.show.review_session'), review_session_path(@review.review_session)],
      [I18n.t('reviews.show.review'), '#']
    ]
  end

  def edit
    @submissions = apply_scopes(Submission)
                   .in_series(@review.review_session.series)
                   .where(user: @review.review_user.user, exercise: @review.review_exercise.exercise)
                   .paginate(page: parse_pagination_param(params[:page]))
    @crumbs = [
      [@review.review_session.series.course.name, course_url(@review.review_session.series.course)],
      [@review.review_session.series.name, breadcrumb_series_path(@review.review_session.series, current_user)],
      [I18n.t('review_sessions.show.review_session'), review_session_path(@review.review_session)],
      [I18n.t('reviews.edit.short_title'), '#']
    ]
  end

  def update
    @auto_mark = params[:auto_mark]
    @review.update(permitted_attributes(@review))
    respond_to do |format|
      format.html { redirect_to review_session_review_path(@review.review_session, @review) }
      format.json { render :show, status: :ok, location: @review }
      format.js
    end
  end

  private

  def set_review
    @review = Review.find(params[:id])
    authorize @review
  end
end
