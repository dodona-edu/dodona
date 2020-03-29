class AnnotationController < ApplicationController
  before_action :set_submission
  skip_before_action :verify_authenticity_token if Rails.env.development?

  def create
    authorize Annotation
    @annotation = Annotation.new(permitted_attributes(Annotation))
    @annotation.user = current_user
    @annotation.submission = @submission
    if @annotation.save
      render json: @annotation
    else
      render json: @annotation.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @annotation
    if @annotation.update(permitted_attributes(@annotation))
      render json: @annotation
    else
      render json: @annotation.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @annotation
    if @annotation.destroy
      render json: {}, status: :no_content
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  private

  def set_submission
    @submission = Submission.find params[:submission_id]
    @annotation = Annotation.find params[:annotation_id] if params[:annotation_id]
  end
end
