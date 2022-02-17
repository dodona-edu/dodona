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

    @user_labels = @feedback.evaluation
                            .series
                            .course
                            .course_memberships
                            .find_by(user_id: @feedback.user)
                            .course_labels

    @score_map = @feedback.scores.index_by(&:score_item_id)
    # If we refresh all scores because of a conflict, we want to make
    # sure the user is aware the update was not successful. By setting
    # the score_item ID in the `warning` param, it will be rendered with
    # the bootstrap warning classes.
    @warning = params[:warning]
    # Don't allow browsers to store this page. This prevents the
    # browser from serving a cached copy when pressing the back
    # button, which can result in problems if the user entered some
    # data, goes to the next student, and presses the back button.
    # See https://github.com/dodona-edu/dodona/issues/2813 for more
    # context. Note that this does mean we have to retransmit the page
    # every time, where previously we could rely on ETag to avoid
    # retransmitting the page if nothing changed.
    # This should be replaced with a simple `no_store` on the next
    # rails release: https://github.com/rails/rails/pull/40324
    response.cache_control = 'no-store'
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
    attrs = permitted_attributes(@feedback)
    attrs['scores_attributes'].each { |s| s['last_updated_by_id'] = current_user.id } if attrs['scores_attributes'].present?

    # Reset scores if a new exercise is chosen
    @feedback.scores.each { |s| s.destroy } if attrs['submission_id'].present? && attrs['submission_id'] != @feedback.submission_id

    updated = @feedback.update(attrs)

    # We might have updated scores, so recalculate the map.
    @score_map = @feedback.scores.index_by(&:score_item_id)

    respond_to do |format|
      if updated
        format.html { redirect_to evaluation_feedback_path(@feedback.evaluation, @feedback) }
        format.json { render :show, status: :ok, location: @feedback }
        format.js { render :show }
      else
        format.json { render json: @feedback.errors, status: :unprocessable_entity }
        format.js { render :show, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
    authorize @feedback
    @score_map = @feedback.scores.index_by(&:score_item_id)
  end
end
