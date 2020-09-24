class AnnotationsController < ApplicationController
  before_action :set_submission, only: %i[create]
  before_action :set_annotation, only: %i[show update destroy]

  has_scope :by_submission, as: :submission_id
  has_scope :by_user, as: :user_id

  def index
    authorize Annotation
    @annotations = apply_scopes(policy_scope(Annotation.all))
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
