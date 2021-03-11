class AnnotationsController < ApplicationController
  before_action :set_submission, only: %i[create]
  before_action :set_annotation, only: %i[show update destroy]

  has_scope :by_submission, as: :submission_id
  has_scope :by_user, as: :user_id
  has_scope :by_course, as: :course_id

  has_scope :by_filter, as: 'filter' do |controller, scope, value|
    scope.by_filter(value, skip_user: controller.params[:user_id].present?, skip_exercise: controller.params[:exercise_id].present?)
  end

  def index
    authorize Annotation
    @annotations = apply_scopes(policy_scope(Annotation.all))
  end

  def question_index
    authorize Question, :index?
    @user = User.find(params[:user_id]) if params[:user_id]

    @questions = policy_scope(Question).merge(apply_scopes(Question).all)
    @questions = @questions.where(question_state: params[:question_state]) if params[:question_state]

    @unfiltered = @user.nil? && params[:course_id].nil?

    # By default, filter only for the courses a user is an admin of, unless we are in filtering by course or user, or
    # the user has explicitly asked to view all questions.
    if @unfiltered && current_user&.a_course_admin? && !ActiveRecord::Type::Boolean.new.deserialize(params[:everything])
      @questions = @questions.where(
        course_id: current_user.administrating_courses.map(&:id)
      )
    end

    # Preload dependencies for efficiency
    @questions = @questions.includes(:user, :last_updated_by, submission: %i[exercise course])

    @questions = @questions.order(created_at: :desc).paginate(page: parse_pagination_param(params[:page]))
    @activities = policy_scope(Activity.all)
    @courses = policy_scope(Course.all)
    @title = I18n.t('questions.index.title')
    @crumbs = []
    @crumbs << [@user.full_name, user_path(@user)] if @user.present?
    @crumbs << [@title, '#']
  end

  def show; end

  def create
    # Fail fast if not logged in; otherwise we would always assume a question.
    raise Pundit::NotAuthorizedError, 'Unauthorized' if current_user.blank?

    clazz = if current_user.course_admin?(@submission.course)
              Annotation
            else
              Question
            end
    args = permitted_attributes(clazz)
    args[:user] = current_user
    args[:submission] = @submission

    @annotation = clazz.new(args)

    authorize @annotation
    respond_to do |format|
      if @annotation.save
        format.json { render :show, status: :created, location: @annotation.becomes(Annotation), as: Annotation }
      else
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      args = permitted_attributes(@annotation)
      args[:last_updated_by] = current_user
      if @annotation.update(args)
        format.json { render :show, status: :ok, location: @annotation.becomes(Annotation) }
      else
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @annotation.destroy
    render json: {}, status: :no_content
  end

  private

  def set_submission
    @submission = Submission.find_by(id: params[:submission_id])
  end

  def set_annotation
    @annotation = Annotation.find(params[:id])
    @annotation.transition_from = params[:from] if @annotation.is_a?(Question)
    @annotation.transition_to = params[:question]&.[](:question_state) if @annotation.is_a?(Question)
    authorize @annotation
  end
end
