class EvaluationsController < ApplicationController
  include SeriesHelper
  include EvaluationHelper

  before_action :set_evaluation, only: %i[show edit update destroy overview set_multi_user add_user remove_user mark_undecided_complete export_grades modify_grading_visibility]
  before_action :set_series, only: %i[new]

  has_scope :by_institution, as: 'institution_id'
  has_scope :by_filter, as: 'filter'
  has_scope :by_course_labels, as: 'course_labels', type: :array do |controller, scope, value|
    if controller.params[:action] == 'show'
      scope.by_course_labels(value, Evaluation.find(controller.params[:id]).series.course_id)
    else
      scope.by_course_labels(value)
    end
  end

  def show
    if @evaluation.users.count == 0
      flash[:alert] = I18n.t('evaluations.edit.users_required')
      redirect_to edit_evaluation_path(@evaluation)
      return
    end
    @feedbacks = @evaluation.evaluation_sheet
    @users = apply_scopes(@evaluation.users)
    @course_labels = CourseLabel.where(course: @evaluation.series.course)
    @crumbs = [[@evaluation.series.course.name, course_url(@evaluation.series.course)], [@evaluation.series.name, breadcrumb_series_path(@evaluation.series, current_user)], [I18n.t('evaluations.show.evaluation'), '#']]
    @title = I18n.t('evaluations.show.evaluation')
  end

  def new
    if @series.evaluation.present?
      redirect_to evaluation_path(@series.evaluation)
      return
    end
    @course = @series.course
    @evaluation = Evaluation.new(series: @series, deadline: @series.deadline || Time.current)
    @crumbs = [
      [@series.course.name, course_url(@series.course)],
      [@series.name, breadcrumb_series_path(@series, current_user)],
      [I18n.t('evaluations.new.create_evaluation'), '#']
    ]
    @title = I18n.t('evaluations.new.create_evaluation')
    authorize @evaluation
  end

  def edit
    @should_confirm = params[:confirm].present?
    @course = @evaluation.series.course
    @course_labels = CourseLabel.where(course: @course)
    @course_memberships = apply_scopes(@course.course_memberships)
                          .includes(:course_labels, user: [:institution])
                          .order(status: :asc)
                          .order(Arel.sql('users.permission ASC'))
                          .order(Arel.sql('users.last_name ASC'), Arel.sql('users.first_name ASC'))
                          .where(status: %i[course_admin student])
                          .paginate(page: parse_pagination_param(params[:page]), per_page: 15)

    ActivityStatus.add_status_for_series(@evaluation.series, [:last_submission])

    @crumbs = [
      [@evaluation.series.course.name, course_url(@evaluation.series.course)],
      [@evaluation.series.name, breadcrumb_series_path(@evaluation.series, current_user)],
      [I18n.t('evaluations.show.evaluation'), evaluation_url(@evaluation)],
      [I18n.t('evaluations.edit.title'), '#']
    ]
    @title = I18n.t('evaluations.edit.title')
  end

  def create
    @evaluation = Evaluation.new(permitted_attributes(Evaluation))
    authorize @evaluation
    @evaluation.exercises = @evaluation.series.exercises
    @course = @evaluation.series.course
    @course_labels = CourseLabel.where(course: @course)
    @course_memberships = apply_scopes(@course.course_memberships)
                          .includes(:course_labels, user: [:institution])
                          .order(status: :asc)
                          .order(Arel.sql('users.permission ASC'))
                          .order(Arel.sql('users.last_name ASC'), Arel.sql('users.first_name ASC'))
                          .where(status: %i[course_admin student])
                          .paginate(page: parse_pagination_param(params[:page]), per_page: 15)

    respond_to do |format|
      if @evaluation.save
        @user_count_course = @evaluation.series.course.enrolled_members.count
        @user_count_series = @evaluation.series.course.enrolled_members.where(id: Submission.where(exercise_id: @evaluation.exercises, course_id: @evaluation.series.course_id).select('DISTINCT user_id')).count
        format.js {}
        format.json { render :show, status: :created, location: @evaluation }
      else
        format.js { render :new }
        format.json { render json: @evaluation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @evaluation.update(permitted_attributes(@evaluation))
        format.html { redirect_to evaluation_path(@evaluation), notice: I18n.t('controllers.updated', model: Evaluation.model_name.human) }
        format.json { render :show, status: :ok, location: @evaluation }
      else
        format.html { render :edit }
        format.json { render json: @evaluation.errors, status: :unprocessable_entity }
      end
    end
  end

  def modify_grading_visibility
    new_visibility = ActiveModel::Type::Boolean.new.cast(params[:visible])
    @evaluation.change_grade_visibility!(new_visibility)
    redirect_back fallback_location: evaluation_score_items_path(@evaluation)
  end

  def set_multi_user
    users = case params[:type]
            when 'enrolled'
              @evaluation.series.course.enrolled_members
            when 'submitted'
              @evaluation.series.course.enrolled_members.where(id: Submission.where(exercise_id: @evaluation.exercises, course_id: @evaluation.series.course_id).select('DISTINCT user_id'))
            when 'none'
              []
            end
    @evaluation.update(users: users) unless users.nil?
    render 'refresh_users'
  end

  def add_user
    @course = @evaluation.series.course
    @course_membership = @course.course_memberships.find_by(user_id: params[:user_id])
    @user = @course_membership.user
    @evaluation.update(users: @evaluation.users + [@user])
  end

  def remove_user
    @course = @evaluation.series.course
    @course_membership = @course.course_memberships.find_by(user_id: params[:user_id])
    @user = @course_membership.user
    @evaluation.update(users: @evaluation.users - [@user])
  end

  def mark_undecided_complete
    @evaluation.feedbacks.undecided.find_each { |f| f.update(completed: true) }
  end

  def destroy
    @evaluation.destroy
    respond_to do |format|
      format.html { redirect_to course_url(@evaluation.series.course, anchor: @evaluation.series.anchor), notice: I18n.t('controllers.destroyed', model: Evaluation.model_name.human) }
      format.json { head :no_content }
    end
  end

  def overview
    @crumbs = [
      [@evaluation.series.course.name, course_url(@evaluation.series.course)],
      [@evaluation.series.name, breadcrumb_series_path(@evaluation.series, current_user)],
      [I18n.t('evaluations.overview.title'), '#']
    ]
    @title = I18n.t('evaluations.overview.title')
    @feedbacks = Feedback.joins(:evaluation_user)
                         .where(evaluation: @evaluation, evaluation_users: { user: current_user })
                         .includes(:evaluation_exercise, scores: :score_item)
                         .order('evaluation_exercises.id')
    @feedbacks = policy_scope(@feedbacks)
  end

  def export_grades
    respond_to do |format|
      format.csv do
        send_data @evaluation.grades_csv, type: 'text/csv', disposition: "attachment; filename=export-#{@evaluation.id}.csv"
      end
    end
  end

  private

  def set_evaluation
    @evaluation = Evaluation.includes(%i[evaluation_users evaluation_exercises feedbacks users exercises]).find(params[:id])
    authorize @evaluation
  end

  def set_series
    @series = Series.find(params[:series_id])
  end
end
