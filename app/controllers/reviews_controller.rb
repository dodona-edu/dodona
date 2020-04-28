class ReviewsController < ApplicationController
  before_action :set_review, only: %i[show update]

  def show
    @crumbs = [
      [@review.review_session.series.course.name, course_url(@review_session.series.course)],
      [@review.review_session.series.name, series_url(@review.review_session.series)],
      [I18n.t('review_session.show.review_session'), review_session_path(@review.review_session)],
      [I18n.t('reviews.show.review'), '#']
    ]
  end

  def update
    respond_to do |format|
      if @review.update(permitted_attributes(@review))
        format.html { redirect_to review_review_session_path(@review.review_session, @review) }
        format.json { render :show, status: :ok, location: @review }
      else
        format.html { redirect_to review_review_session_path(@review.review_session, @review), alert: I18n.t('review.completed.failure') }
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_review
    @review = Review.find(params[:id])
    authorize @review
  end
end
