class SubmissionsController < ApplicationController
  before_action :set_submission, only: %i[show download evaluate edit media]
  before_action :set_submissions, only: %i[index mass_rejudge]
  before_action :ensure_trailing_slash, only: :show

  has_scope :by_filter, as: 'filter' do |controller, scope, value|
    scope.by_filter(value, skip_user: controller.params[:user_id].present?, skip_exercise: controller.params[:activity_id].present?)
  end

  has_scope :by_status, as: 'status'

  has_scope :by_course_labels, as: 'course_labels', type: :array do |controller, scope, value|
    course = Course.find_by(id: controller.params[:course_id]) if controller.params[:course_id].present?
    if course.present? && controller.current_user&.course_admin?(course) && controller.params[:user_id].nil?
      scope.by_course_labels(value, controller.params[:course_id])
    else
      scope
    end
  end

  content_security_policy only: %i[show] do |policy|
    # allow sandboxed tutor
    policy.frame_src -> { [sandbox_url] }
  end

  def index
    authorize Submission
    @submissions = @submissions.includes(:annotations).paginate(page: parse_pagination_param(params[:page]))

    # If the result is the same, don't send it.
    return unless stale?(@submissions)
    # If returning non-HTML, we are done.
    return unless request.format.html?

    @title = I18n.t('submissions.index.title')
    @crumbs = []
    if @user
      @crumbs << if @course.present?
                   [@user.full_name, course_member_path(@course, @user)]
                 else
                   [@user.full_name, user_path(@user)]
                 end
    elsif @series
      @crumbs << [@series.course.name, course_path(@series.course)] << [@series.name, @series.hidden? ? series_path(@series) : course_path(@series.course, anchor: @series.anchor)]
    elsif @course
      @crumbs << [@course.name, course_path(@course)]
    elsif @judge
      @crumbs << [@judge.name, judge_path(@judge)]
    end
    @crumbs << [@activity.name, helpers.activity_scoped_path(activity: @exercise, series: @series, course: @course)] if @exercise
    @crumbs << [I18n.t('submissions.index.title'), '#']
  end

  def show
    @title = "#{I18n.t('submissions.show.submission')} - #{@submission.exercise.name}"
    course = @submission.course
    @crumbs = if course.present?
                [[course.name, course_path(course)], [@submission.exercise.name, course_activity_path(course, @submission.exercise)], [I18n.t('submissions.show.submission'), '#']]
              else
                [[@submission.exercise.name, activity_path(@submission.exercise)], [I18n.t('submissions.show.submission'), '#']]
              end
    @feedbacks = policy_scope(@submission.feedbacks).preload(scores: :score_item)
  end

  def create
    authorize Submission
    para = permitted_attributes(Submission)
    para[:user_id] = current_user.id
    para[:code].gsub!(/\r\n?/, "\n")
    para[:evaluate] = true # immediately evaluate after create
    course = Course.find(para[:course_id]) if para[:course_id].present?
    para.delete(:course_id) if para[:course_id].present? && course.subscribed_members.exclude?(current_user)
    submission = Submission.new(para)
    can_submit = true
    if submission.exercise.present?
      can_submit &&= Pundit.policy!(current_user, submission.exercise).submit?
      can_submit &&= submission.exercise.accessible?(current_user, course)
    end
    if can_submit && submission.save
      render json: { status: 'ok', id: submission.id, exercise_id: submission.exercise_id, course_id: submission.course_id, url: submission_url(submission, format: :json) }
    else
      submission.errors.add(:exercise, 'not permitted') unless can_submit
      render json: { status: 'failed', errors: submission.errors }, status: :unprocessable_entity
    end
  end

  def edit
    respond_to do |format|
      format.html do
        if @submission.course.nil?
          redirect_to activity_url(@submission.exercise, anchor: 'submission-card', edit_submission: @submission)
        else
          redirect_to course_activity_url(@submission.course, @submission.exercise, anchor: 'submission-card', edit_submission: @submission)
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
    redirect_to media_activity_url(@submission.exercise, params[:media], token: params[:token])
  end

  def mass_rejudge
    authorize Submission
    Event.create(event_type: :rejudge, user: current_user, message: "#{@submissions.count} submissions")
    Submission.rejudge_delayed(@submissions)
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
      @course_labels = CourseLabel.where(course: @course) if @user.blank? && current_user&.course_admin?(@course)
    end

    @series = Series.find(params[:series_id]) if params[:series_id]
    @activity = Exercise.find(params[:activity_id]) if params[:activity_id]
    @judge = Judge.find(params[:judge_id]) if params[:judge_id]

    if @activity
      @submissions = @submissions.of_exercise(@activity)
      if @course
        @submissions = @submissions.in_course(@course)
      elsif @series
        @submissions = @submissions.in_course(@series.course)
      end
    elsif @series
      @submissions = @submissions.in_series(@series)
    elsif @course
      @submissions = @submissions.in_course(@course)
    elsif @judge
      @submissions = @submissions.of_judge(@judge)
    end

    @course_membership = CourseMembership.find_by(user: @user, course: @course) if @user.present? && @course.present?

    # this cannot use has_scope, because we need the scopes in this method
    # to be applied before this one
    @submissions = @submissions.most_recent_correct_per_user if params[:most_recent_correct_per_user]
  end
end
