class ReviewsController < ApplicationController
  include SeriesHelper

  before_action :set_review, only: %i[show update]

  def show
    @crumbs = [
      [@review.review_session.series.course.name, course_url(@review.review_session.series.course)],
      [@review.review_session.series.name, breadcrumb_series_path(@review.review_session.series, current_user)],
      [I18n.t('review_sessions.show.review_session'), review_session_path(@review.review_session)],
      [I18n.t('reviews.show.review'), '#']
    ]
  end

  def update
    @review.update(permitted_attributes(@review))
    respond_to do |format|
      format.html { redirect_to review_session_review_path(@review.review_session, @review) }
      format.json { render :show, status: :ok, location: @review }
    end
  end

  private

  def set_review
    @review = Review.find(params[:id])
    authorize @review
  end
end
