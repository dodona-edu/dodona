class SubmissionsController < ApplicationController
  before_action :set_submission, only: %i[show download evaluate edit media]
  before_action :set_submissions, only: %i[index mass_rejudge]

  skip_before_action :verify_authenticity_token, only: [:create]

  has_scope :by_filter, as: 'filter'

  def index
    authorize Submission
    @submissions = @submissions.paginate(page: params[:page])
    @title = I18n.t('submissions.index.title')
    @crumbs = []
    if @user
      @crumbs << [@user.full_name, user_path(@user)]
    else
      if @series
        @crumbs << [@series.course.name, course_path(@series.course)] << [@series.name, series_path(@series)]
      elsif @course
        @crumbs << [@course.name, course_path(@course)]
      end
    end
    if @exercise
      @crumbs << [@exercise.name, helpers.exercise_scoped_path(exercise: @exercise, series: @series, course: @course)]
    end
    @crumbs << [I18n.t('submissions.index.title'), "#"]
  end

  def show
    @title = I18n.t('submissions.show.submission')
    course = @submission.course
    if course.present?
      @crumbs = [[course.name, course_path(course)], [@submission.exercise.name, course_exercise_path(course, @submission.exercise)], [I18n.t('submissions.show.submission'), "#"]]
    else
      @crumbs = [[@submission.exercise.name, exercise_path(@submission.exercise)], [I18n.t('submissions.show.submission'), "#"]]
    end
  end

  def create
    authorize Submission
    para = permitted_attributes(Submission)
    para[:user_id] = current_user.id
    para[:code].gsub!(/\r\n?/, "\n")
    para[:evaluate] = true # immediately evaluate after create
    if para[:course_id].present?
      para.delete(:course_id) unless Course.find(para[:course_id]).subscribed_members.include?(current_user)
    end
    @submission = Submission.new(para)
    can_submit = true
    if @submission.exercise.present?
      can_submit &&= Pundit.policy!(UserContext.new(current_user, request.headers['X-Forwarded-For']), @submission.exercise).submit?
      can_submit &&= current_user.can_access?(@submission.course, @submission.exercise)
    end
    if can_submit && @submission.save
      render json: { status: 'ok', id: @submission.id, url: submission_url(@submission, format: :json) }
    else
      @submission.errors.add(:exercise, :not_permitted) unless can_submit
      render json: { status: 'failed', errors: @submission.errors }, status: :unprocessable_entity
    end
  end

  def edit
    respond_to do |format|
      format.html do
        if @submission.course.nil?
          redirect_to exercise_url(@submission.exercise, anchor: 'submission-card', edit_submission: @submission)
        else
          redirect_to course_exercise_url(@submission.course, @submission.exercise, anchor: 'submission-card', edit_submission: @submission)
        end
      end
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

    # this cannot use has_scope, because we need the scopes in this method
    # to be applied before this one
    if params[:most_recent_correct_per_user]
      @submissions = @submissions.most_recent_correct_per_user
    end
  end
end
