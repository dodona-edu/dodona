class SavedAnnotationsController < ApplicationController
  set_pagination_headers :saved_annotations, only: [:index]
  before_action :set_saved_annotation, only: %i[show update destroy edit]

  has_scope :by_user, as: 'user_id'
  has_scope :by_course, as: 'course_id'
  has_scope :by_exercise, as: 'exercise_id'
  has_scope :by_filter, as: 'filter'

  def index
    authorize SavedAnnotation
    @saved_annotations = apply_scopes(policy_scope(SavedAnnotation.all))
                         .includes(:course).includes(:user).includes(:exercise)
                         .paginate(page: parse_pagination_param(params[:page]), per_page: parse_pagination_param(params[:per_page]))
  end

  def show
    respond_to do |format|
      format.html do
        @submissions = @saved_annotation.submissions.paginate(page: parse_pagination_param(params[:page]))
      end
      format.json
    end
  end

  def edit; end

  def create
    annotation = Annotation.find(params[:from])
    authorize annotation, :show?
    @saved_annotation = SavedAnnotation.new(permitted_attributes(SavedAnnotation).merge({ user: current_user, course: annotation.course, exercise: annotation.submission.exercise }))
    authorize @saved_annotation
    respond_to do |format|
      if @saved_annotation.save
        annotation.update(saved_annotation: @saved_annotation)
        format.json { render :show, status: :created, location: @saved_annotation }
      else
        format.json { render json: @saved_annotation.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @saved_annotation.update(permitted_attributes(SavedAnnotation))
        format.json { render :show, status: :ok, location: @saved_annotation }
        format.html do
          @submissions = @saved_annotation.submissions.paginate(page: parse_pagination_param(params[:page]))
          render :show
        end
      else
        format.json { render json: @saved_annotation.errors.full_messages, status: :unprocessable_entity }
        format.html { render :edit }
      end
    end
  end

  def destroy
    @saved_annotation.destroy
  end

  private

  def set_saved_annotation
    @saved_annotation = SavedAnnotation.find(params[:id])
    authorize @saved_annotation
  end
end
