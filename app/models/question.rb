class Question < Annotation
  before_create :set_question_state

  enum question_state: { unanswered: 0, in_progress: 1, answered: 2 }
  alias_attribute :question_text, :annotation_text

  default_scope { order(created_at: :desc) }

  # Fix for routing. Otherwise it would require question_url instead of the annotation_url
  def self.model_name
    superclass.model_name
  end

  # Fix the above fix
  def self.policy_class
    QuestionPolicy
  end

  def mark_unresolved
    self.question_state = :unanswered
    save
  end

  def mark_in_progress
    self.question_state = :in_progress
    save
  end

  def mark_resolved
    self.question_state = :answered
    save
  end

  # Disable notification creation & deletion
  def create_notification; end

  def destroy_notification; end

  private

  def set_question_state
    self.question_state = :unanswered
  end
end
