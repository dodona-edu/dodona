class SubmissionsController < ApplicationController
  before_action :set_submission, only: %i[show download evaluate edit media]
  before_action :set_submissions, only: %i[index mass_rejudge]

  skip_before_action :verify_authenticity_token, only: [:create]

  has_scope :by_filter, as: 'filter' do |controller, scope, value|
    scope.by_filter(value, controller.params[:user_id].present?, controller.params[:exercise_id].present?, controller.params[:most_recent_correct_per_user].present?)
  end

  has_scope :by_course_labels, as: 'course_labels', type: :array do |controller, scope, value|
    if controller.params[:course_id].present? && controller.params[:user_id].nil?
      scope.by_course_labels(value, controller.params[:course_id])
    else
      scope
    end
  end

  def index
    authorize Submission
    @submissions = @submissions.paginate(page: parse_pagination_param(params[:page]))
    @title = I18n.t('submissions.index.title')
    @crumbs = []
    if @user
      if @course.present?
        @crumbs << [@user.full_name, course_member_path(@course, @user)]
      else
        @crumbs << [@user.full_name, user_path(@user)]
      end
    else
      if @series
        @crumbs << [@series.course.name, course_path(@series.course)] << [@series.name, @series.hidden? ? series_path(@series) : course_path(@series.course, anchor: @series.anchor)]
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
      can_submit &&= Pundit.policy!(current_user, @submission.exercise).submit?
      can_submit &&= @submission.exercise.accessible?(current_user, @submission.course)
    end
    if can_submit && @submission.save
      render json: {status: 'ok', id: @submission.id, url: submission_url(@submission, format: :json)}
    else
      @submission.errors.add(:exercise, :not_permitted) unless can_submit
      render json: {status: 'failed', errors: @submission.errors}, status: :unprocessable_entity
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
    render json: {status: 'ok', message: I18n.t('submissions.index.reevaluating_submissions', count: @submissions.length)}
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
      @course_labels = CourseLabel.where(course: @course) unless @user.present?
    end
    if params[:series_id]
      @series = Series.find(params[:series_id])
    end
    if params[:exercise_id]
      @exercise = Exercise.find(params[:exercise_id])
    end

    if @exercise
      @submissions = @submissions.of_exercise(@exercise)
      if @course
        @submissions = @submissions.in_course(@course) if current_user&.member_of?(@course)
      elsif @series
        @submissions = @submissions.in_course(@series.course) if current_user&.member_of?(@series.course)
      end
    elsif @series
      @submissions = @submissions.in_series(@series) if current_user&.member_of?(@series.course)
    elsif @course
      @submissions = @submissions.in_course(@course) if current_user&.member_of?(@course)
    end

    if @user.present? && @course.present?
      @course_membership = CourseMembership.find_by(user: @user, course: @course)
    end

    # this cannot use has_scope, because we need the scopes in this method
    # to be applied before this one
    if params[:most_recent_correct_per_user]
      @submissions = @submissions.most_recent_correct_per_user
    end
  end
end
