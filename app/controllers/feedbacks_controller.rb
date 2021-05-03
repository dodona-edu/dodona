class FeedbacksController < ApplicationController
  include SeriesHelper

  before_action :set_feedback, only: %i[show edit update]

  has_scope :by_filter, as: 'filter' do |_controller, scope, value|
    scope.by_filter(value, skip_user: true, skip_exercise: true)
  end

  has_scope :by_status, as: 'status'

  content_security_policy only: %i[show] do |policy|
    # allow sandboxed tutor
    policy.frame_src -> { [sandbox_url] }
  end

  def show
    @crumbs = [
      [@feedback.evaluation.series.course.name, course_url(@feedback.evaluation.series.course)],
      [@feedback.evaluation.series.name, breadcrumb_series_path(@feedback.evaluation.series, current_user)],
      [I18n.t('evaluations.show.evaluation'), evaluation_path(@feedback.evaluation)],
      [I18n.t('feedbacks.show.feedback'), '#']
    ]
    @title = I18n.t('feedbacks.show.feedback')
  end

  def edit
    @submissions = apply_scopes(Submission)
                   .in_series(@feedback.evaluation.series)
                   .where(user: @feedback.user, exercise: @feedback.exercise)
                   .paginate(page: parse_pagination_param(params[:page]))
    @crumbs = [
      [@feedback.evaluation.series.course.name, course_url(@feedback.evaluation.series.course)],
      [@feedback.evaluation.series.name, breadcrumb_series_path(@feedback.evaluation.series, current_user)],
      [I18n.t('evaluations.show.evaluation'), evaluation_path(@feedback.evaluation)],
      [I18n.t('feedbacks.edit.short_title'), '#']
    ]
    @title = I18n.t('feedbacks.edit.short_title')
  end

  def update
    @feedback.update(permitted_attributes(@feedback))
    respond_to do |format|
      format.html { redirect_to evaluation_feedback_path(@feedback.evaluation, @feedback) }
      format.json { render :show, status: :ok, location: @feedback }
      format.js
    end
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
    authorize @feedback
  end
end
