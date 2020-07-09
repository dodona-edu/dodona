class AnnotationsController < ApplicationController
  before_action :set_submission, only: %i[create]
  before_action :set_annotation, only: %i[show update destroy unresolve in_progress resolved]

  has_scope :by_submission, as: :submission_id
  has_scope :by_user, as: :user_id

  def index
    authorize Annotation
    @annotations = apply_scopes(policy_scope(Annotation.all))
  end

  def show; end

  def create
    args = permitted_attributes(Annotation)
    args[:user] = current_user
    args[:submission] = @submission

    @annotation = if current_user.student?
                    Question.new(args)
                  else
                    Annotation.new(args)
                  end

    authorize @annotation
    respond_to do |format|
      if @annotation.save
        format.json { render :show, status: :created, location: @annotation, as: Annotation }
      else
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @annotation.update(permitted_attributes(@annotation))
        format.json { render :show, status: :ok, location: @annotation }
      else
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end

  def unresolve
    @annotation.unanswered!
    respond_to do |format|
      format.json { render :show, status: :ok, location: @annotation }
      format.js(&method(:reload_question_table))
    end
  end

  def in_progress
    @annotation.in_progress!
    respond_to do |format|
      format.json { render :show, status: :ok, location: @annotation }
      format.js(&method(:reload_question_table))
    end
  end

  def resolved
    @annotation.answered!
    respond_to do |format|
      format.json { render :show, status: :ok, location: @annotation }
      format.js(&method(:reload_question_table))
    end
  end

  def destroy
    @annotation.destroy
    render json: {}, status: :no_content
  end

  private

  def reload_question_table
    open = @annotation.submission.course.open_questions
    in_progress = @annotation.submission.course.in_progress_questions
    closed = @annotation.submission.course.closed_questions
    render partial: 'courses/reload_questions_table', status: :ok, locals: { open_questions: open, in_progress_questions: in_progress, closed_questions: closed }
  end

  def set_submission
    @submission = Submission.find_by(id: params[:submission_id])
  end

  def set_annotation
    @annotation = Annotation.find(params[:id])
    authorize @annotation
  end
end
