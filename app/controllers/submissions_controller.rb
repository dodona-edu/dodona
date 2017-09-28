class SubmissionsController < ApplicationController
  before_action :set_submission, only: %i[show download evaluate edit media]
  before_action :set_submissions, only: %i[index mass_rejudge]

  skip_before_action :verify_authenticity_token, only: [:create]

  has_scope :by_filter, as: 'filter'

  def index
    authorize Submission
    @submissions = @submissions.paginate(page: params[:page])
    @title = I18n.t('submissions.index.title')
  end

  def show; end

  def create
    authorize Submission
    para = permitted_attributes(Submission)
    para[:user_id] = current_user.id
    para[:code].gsub!(/\r\n?/, "\n")
    @submission = Submission.new(para)
    can_submit = Pundit.policy!(current_user, @submission.exercise).submit?
    if can_submit && @submission.save
      render json: { status: 'ok', id: @submission.id }
    else
      @submission.errors.add(:exercise, :not_permitted) unless can_submit
      render json: { status: 'failed', errors: @submission.errors }, status: :unprocessable_entity
    end
  end

  def edit
    respond_to do |format|
      format.html {
        if @submission.course.nil?
          redirect_to exercise_url(@submission.exercise, anchor: 'submission-card', edit_submission: @submission)
        else
          redirect_to course_exercise_url(@submission.course, @submission.exercise, anchor: 'submission-card', edit_submission: @submission)
        end
      }
    end
  end

  def download
    data = @submission.code
    filename = @submission.exercise.file_name
    send_data data, type: 'application/octet-stream', filename: filename, disposition: 'attachment', x_sendfile: true
  end

  def evaluate
    @submission.evaluate_delayed
    redirect_to(@submission)
  end

  def media
    redirect_to media_exercise_url(@submission.exercise, params[:media])
  end

  def mass_rejudge
    authorize Submission
    Submission.rejudge(@submissions)
    render json: { status: 'ok', message: I18n.t('submissions.index.reevaluating_submissions', count: @submissions.length) }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_submission
    @submission = Submission.find(params[:id])
    authorize @submission
  end

  def set_submissions
    @submissions = policy_scope(Submission).merge(apply_scopes(Submission).all)
    if params[:user_id]
      @user = User.find(params[:user_id])
      @submissions = @submissions.of_user(@user)
    end
    if params[:course_id]
      @course = Course.find(params[:course_id])
      @submissions = @submissions.in_course(@course)
    end
    if params[:series_id]
      @series = Series.find(params[:series_id])
      @submissions = @submissions.in_series(@series)
    end
    if params[:exercise_id]
      @exercise = Exercise.find(params[:exercise_id])
      @submissions = @submissions.of_exercise(@exercise)
    end
  end
end
