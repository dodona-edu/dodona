class SavedAnnotationsController < ApplicationController
  include Sortable
  set_pagination_headers :saved_annotations, only: [:index]
  before_action :set_saved_annotation, only: %i[show update destroy edit]

  has_scope :by_user, as: 'user_id'
  has_scope :by_course, as: 'course_id'
  has_scope :by_exercise, as: 'exercise_id'
  has_scope :by_filter, as: 'filter'

  has_scope :by_exercise, as: :exercise_id, only: :new
  has_scope :by_course, as: :course_id, only: :new

  order_by :annotations_count, :title, :annotation_text

  def index
    authorize SavedAnnotation
    @title = I18n.t('saved_annotations.index.title')
    @crumbs = [[I18n.t('saved_annotations.index.title'), saved_annotations_path]]
    saved_annotations = policy_scope(SavedAnnotation.order_by_annotations_count(:DESC))
    @courses = Course.where(id: saved_annotations.pluck(:course_id).uniq)
    @exercises = Activity.where(id: saved_annotations.pluck(:exercise_id).uniq)
    @saved_annotations = apply_scopes(saved_annotations)
                         .includes(:course).includes(:user).includes(:exercise)
                         .paginate(page: parse_pagination_param(params[:page]), per_page: parse_pagination_param(params[:per_page]))
  end

  def show
    respond_to do |format|
      format.html do
        @title = @saved_annotation.title
        @crumbs = [[I18n.t('saved_annotations.index.title'), saved_annotations_path], [@saved_annotation.title, saved_annotation_path(@saved_annotation)]]
        @annotations = @saved_annotation.annotations.paginate(page: parse_pagination_param(params[:page]))
      end
      format.json
    end
  end

  def new
    authorize SavedAnnotation
    @annotations = AnnotationPolicy::Scope.new(current_user, Annotation.all).resolve
    @annotations = @annotations.where(saved_annotation_id: nil).where(user_id: current_user.id)
    @courses = Course.where(id: @annotations.joins(:submission).pluck("submissions.course_id").uniq)
    @exercises = Activity.where(id: @annotations.joins(:submission).pluck("submissions.exercise_id").uniq)
    @annotations = apply_scopes(@annotations)
                   .includes(:course).includes(:user).includes(:submission)
                   .paginate(page: parse_pagination_param(params[:page]), per_page: parse_pagination_param(params[:per_page]))

    @title = I18n.t('saved_annotations.new.title')
    @crumbs = [[I18n.t('saved_annotations.index.title'), saved_annotations_path], [I18n.t('saved_annotations.new.title'), '#']]
  end

  def edit
    @title = I18n.t('saved_annotations.edit.title')
    @crumbs = [[I18n.t('saved_annotations.index.title'), saved_annotations_path], [@saved_annotation.title, saved_annotation_path(@saved_annotation)], [I18n.t('saved_annotations.edit.title'), '#']]
  end

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
          redirect_to saved_annotation_path(@saved_annotation)
        end
      else
        format.json { render json: @saved_annotation.errors.full_messages, status: :unprocessable_entity }
        format.html do
          @crumbs = [[I18n.t('saved_annotations.index.title'), saved_annotations_path], [@saved_annotation.title, saved_annotation_path(@saved_annotation)], [I18n.t('saved_annotations.edit.title'), '#']]
          render :edit
        end
      end
    end
  end

  def destroy
    @saved_annotation.destroy
    redirect_to saved_annotations_url
  end

  private

  def set_saved_annotation
    @saved_annotation = SavedAnnotation.find(params[:id])
    authorize @saved_annotation
  end
end
