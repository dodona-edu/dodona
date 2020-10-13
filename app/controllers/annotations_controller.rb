class AnnotationsController < ApplicationController
  before_action :set_submission, only: %i[create]
  before_action :set_annotation, only: %i[show update destroy]

  has_scope :by_submission, as: :submission_id
  has_scope :by_user, as: :user_id

  has_scope :by_filter, as: 'filter' do |controller, scope, value|
    scope.by_filter(value, skip_user: controller.params[:user_id].present?, skip_exercise: controller.params[:exercise_id].present?)
  end

  def index
    authorize Annotation
    @annotations = apply_scopes(policy_scope(Annotation.all))
  end

  def question_index
    authorize Question, :index?
    @questions = policy_scope(Question).merge(apply_scopes(Question).all)

    if params[:question_state]
      @questions = @questions.where(question_state: params[:question_state])
    end

    if params[:course]
      @course = Course.find(params[:course])
      @questions = @questions.by_course(params[:course])
    elsif params[:course_id]
      @questions = @questions.by_course(params[:course_id])
    end

    if params[:user_id]
      @user = User.find(params[:user_id])
    end

    @course_membership = CourseMembership.find_by(user: @user, course: @course) if @user.present? && @course.present?
    @questions = @questions.order(created_at: :desc).paginate(page: parse_pagination_param(params[:page]))
    @activities = policy_scope(Activity.all)
    @courses = policy_scope(Course.all) if @course.blank?
    @title = I18n.t('questions.index.title')
    @crumbs = []
    @crumbs << [@course.name, course_path(@course)] if @course.present?
    if @user
      @crumbs << if @course.present?
                   [@user.full_name, course_member_path(@course, @user)]
                 else
                   [@user.full_name, user_path(@user)]
                 end
    end
    @crumbs << [@title, '#']
  end

  def show; end

  def create
    clazz = if current_user&.course_admin?(@submission.course)
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
