class EvaluationsController < ApplicationController
  include SeriesHelper
  include EvaluationHelper

  before_action :set_evaluation, only: %i[show edit add_users add_rubrics rubrics update destroy overview set_multi_user add_user remove_user mark_undecided_complete export]
  before_action :set_series, only: %i[new]

  has_scope :by_institution, as: 'institution_id'
  has_scope :by_filter, as: 'filter'
  has_scope :by_course_labels, as: 'course_labels', type: :array

  def show
    redirect_to add_users_evaluation_path(@evaluation) if @evaluation.users.count == 0
    @feedbacks = @evaluation.evaluation_sheet
    @crumbs = [[@evaluation.series.course.name, course_url(@evaluation.series.course)], [@evaluation.series.name, series_url(@evaluation.series)], [I18n.t('evaluations.show.evaluation'), '#']]
    @title = I18n.t('evaluations.show.evaluation')
  end

  def new
    if @series.evaluation.present?
      redirect_to evaluation_path(@series.evaluation)
      return
    end
    @course = @series.course
    @evaluation = Evaluation.new(series: @series, deadline: @series.deadline || Time.current)
    @title = I18n.t('evaluations.new.create_evaluation')
    authorize @evaluation
  end

  def edit
    @course = @evaluation.series.course
    @course_labels = CourseLabel.where(course: @course)
    @course_memberships = apply_scopes(@course.course_memberships)
                          .includes(:course_labels, user: [:institution])
                          .order(status: :asc)
                          .order(Arel.sql('users.permission ASC'))
                          .order(Arel.sql('users.last_name ASC'), Arel.sql('users.first_name ASC'))
                          .where(status: %i[course_admin student])
                          .paginate(page: parse_pagination_param(params[:page]))

    ActivityStatus.add_status_for_series(@evaluation.series, [:last_submission])

    @crumbs = [
      [@evaluation.series.course.name, course_url(@evaluation.series.course)],
      [@evaluation.series.name, series_url(@evaluation.series)],
      [I18n.t('evaluations.show.evaluation'), evaluation_url(@evaluation)],
      [I18n.t('evaluations.edit.title'), '#']
    ]
    @title = I18n.t('evaluations.edit.title')
  end

  def add_users
    edit
    @user_count_course = @evaluation.series.course.enrolled_members.count
    @user_count_series = @evaluation.series.course.enrolled_members.where(id: Submission.where(exercise_id: @evaluation.exercises, course_id: @evaluation.series.course_id).select('DISTINCT user_id')).count
    @crumbs = [
      [@evaluation.series.course.name, course_url(@evaluation.series.course)],
      [@evaluation.series.name, series_url(@evaluation.series)],
      [I18n.t('evaluations.show.evaluation'), evaluation_url(@evaluation)],
      [I18n.t('evaluations.add_users.title'), '#']
    ]
    @title = I18n.t('evaluations.add_users.title')
    @graded = ActiveModel::Type::Boolean.new.cast(params['graded'])
  end

  def add_rubrics
    edit
    @user_count_course = @evaluation.series.course.enrolled_members.count
    @user_count_series = @evaluation.series.course.enrolled_members.where(id: Submission.where(exercise_id: @evaluation.exercises, course_id: @evaluation.series.course_id).select('DISTINCT user_id')).count
    @crumbs = [
      [@evaluation.series.course.name, course_url(@evaluation.series.course)],
      [@evaluation.series.name, series_url(@evaluation.series)],
      [I18n.t('evaluations.show.evaluation'), evaluation_url(@evaluation)],
      [I18n.t('evaluations.add_rubrics.title'), '#']
    ]
    @title = I18n.t('evaluations.add_rubrics.title')
  end

  def rubrics
    edit
    @user_count_course = @evaluation.series.course.enrolled_members.count
    @user_count_series = @evaluation.series.course.enrolled_members.where(id: Submission.where(exercise_id: @evaluation.exercises, course_id: @evaluation.series.course_id).select('DISTINCT user_id')).count
    @crumbs = [
      [@evaluation.series.course.name, course_url(@evaluation.series.course)],
      [@evaluation.series.name, series_url(@evaluation.series)],
      [I18n.t('evaluations.show.evaluation'), evaluation_url(@evaluation)],
      [I18n.t('evaluations.rubrics.title'), '#']
    ]
    @title = I18n.t('evaluations.rubrics.title')
  end

  def create
    @evaluation = Evaluation.new(permitted_attributes(Evaluation))
    authorize @evaluation
    @evaluation.exercises = @evaluation.series.exercises

    respond_to do |format|
      if @evaluation.save
        format.html { redirect_to add_users_evaluation_path(@evaluation, graded: @evaluation.graded) }
        format.json { render :show, status: :created, location: @evaluation }
      else
        format.html { render :new }
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
    user = @evaluation.series.course.subscribed_members.find(params[:user_id])
    @evaluation.update(users: @evaluation.users + [user])
    render 'refresh_users'
  end

  def remove_user
    user = @evaluation.series.course.subscribed_members.find(params[:user_id])
    @evaluation.update(users: @evaluation.users - [user])
    render 'refresh_users'
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
    @feedbacks = policy_scope(Feedback.joins(:evaluation_user).where(evaluation: @evaluation, evaluation_users: { user: current_user }))
    @crumbs = [
      [@evaluation.series.course.name, course_url(@evaluation.series.course)],
      [@evaluation.series.name, breadcrumb_series_path(@evaluation.series, current_user)],
      [I18n.t('evaluations.overview.title'), '#']
    ]
    @title = I18n.t('evaluations.overview.title')
  end

  def export
    respond_to do |format|
      format.csv do
        headers['Content-Type'] = 'text/csv'
        headers['Content-Disposition'] = "attachment; filename=export-#{@evaluation.id}.csv"
        send_data evaluation_to_csv(@evaluation)
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
