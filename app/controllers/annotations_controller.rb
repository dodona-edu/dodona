class AnnotationsController < ApplicationController
  before_action :set_submission, only: %i[create index]
  before_action :set_annotation, only: %i[show update destroy]

  def index
    authorize Annotation
    @annotations = policy_scope(@submission.annotations)
  end

  def show; end

  def create
    args = {
      **permitted_attributes(Annotation),
      user: current_user,
      submission: @submission
    }
    @annotation = Annotation.new(args)
    authorize @annotation
    respond_to do |format|
      if @annotation.save
        format.json { render :show, status: :created, location: @annotation }
      else
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @annotation.update(permitted_attributes(@annotation))
        format.json { render :show, status: ok, location: @annotation }
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
    authorize @annotation
  end
end
