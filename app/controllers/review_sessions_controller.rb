class ReviewSessionsController < ApplicationController
  include SeriesHelper

  before_action :set_review_session, only: %i[show edit update destroy overview set_multi_user add_user remove_user mark_undecided_complete]
  before_action :set_series, only: %i[new]

  has_scope :by_institution, as: 'institution_id'
  has_scope :by_filter, as: 'filter'
  has_scope :by_course_labels, as: 'course_labels', type: :array

  def show
    @reviews = @review_session.review_sheet
    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_sessions.show.review_session'), '#']]
  end

  def new
    if @series.review_session.present?
      redirect_to review_session_path(@series.review_session)
      return
    end
    @course = @series.course
    @review_session = ReviewSession.new(series: @series, deadline: @series.deadline || Time.current)
    authorize @review_session
  end

  def edit
    @course = @review_session.series.course
    @course_labels = CourseLabel.where(course: @course)
    @course_memberships = apply_scopes(@course.course_memberships)
                          .includes(:course_labels, user: [:institution])
                          .order(status: :asc)
                          .order(Arel.sql('users.permission ASC'))
                          .order(Arel.sql('users.last_name ASC'), Arel.sql('users.first_name ASC'))
                          .where(status: %i[course_admin student])
                          .paginate(page: parse_pagination_param(params[:page]))
    @crumbs = [[@review_session.series.course.name, course_url(@review_session.series.course)], [@review_session.series.name, series_url(@review_session.series)], [I18n.t('review_sessions.show.review_session'), review_session_url(@review_session)], [I18n.t('review_sessions.edit.title'), '#']]
  end

  def create
    @review_session = ReviewSession.new(permitted_attributes(ReviewSession))
    authorize @review_session
    @review_session.exercises = @review_session.series.exercises

    respond_to do |format|
      if @review_session.save
        format.html { redirect_to edit_review_session_path(@review_session) }
        format.json { render :show, status: :created, location: @review_session }
      else
        format.html { render :new }
        format.json { render json: @review_session.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @review_session.update(permitted_attributes(@review_session))
        format.html { redirect_to review_session_path(@review_session), notice: I18n.t('controllers.updated', model: ReviewSession.model_name.human) }
        format.json { render :show, status: :ok, location: @review_session }
      else
        format.html { render :edit }
        format.json { render json: @review_session.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_multi_user
    users = case params[:type]
            when 'enrolled'
              @review_session.series.course.enrolled_members
            when 'submitted'
              @review_session.series.course.enrolled_members.where(id: Submission.where(exercise_id: @review_session.exercises, course_id: @review_session.series.course_id).select('DISTINCT user_id'))
            end
    @review_session.update(users: users) unless users.nil?
  end

  def add_user
    user = @review_session.series.course.subscribed_members.find(params[:user_id])
    @review_session.update(users: @review_session.users + [user])
  end

  def remove_user
    user = @review_session.series.course.subscribed_members.find(params[:user_id])
    @review_session.update(users: @review_session.users - [user])
  end

  def mark_undecided_complete
    @review_session.reviews.undecided.find_each { |r| r.update(completed: true) }
  end

  def destroy
    @review_session.destroy
    respond_to do |format|
      format.html { redirect_to course_url(@review_session.series.course, anchor: @review_session.series.anchor), notice: I18n.t('controllers.destroyed', model: ReviewSession.model_name.human) }
      format.json { head :no_content }
    end
  end

  def overview
    @reviews = policy_scope(Review.joins(:review_user).where(review_session: @review_session, review_users: { user: current_user }))
    @crumbs = [
      [@review_session.series.course.name, course_url(@review_session.series.course)],
      [@review_session.series.name, breadcrumb_series_path(@review_session.series, current_user)],
      [I18n.t('review_sessions.overview.title'), '#']
    ]
  end

  private

  def set_review_session
    @review_session = ReviewSession.includes(%i[review_users review_exercises reviews users exercises]).find(params[:id])
    authorize @review_session
  end

  def set_series
    @series = Series.find(params[:series_id])
  end
end
