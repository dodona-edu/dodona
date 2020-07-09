# == Schema Information
#
# Table name: annotations
#
#  id              :bigint           not null, primary key
#  line_nr         :integer
#  submission_id   :integer
#  user_id         :integer
#  annotation_text :text(65535)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  evaluation_id   :bigint
#  type            :string(255)
#  question_state  :integer
#
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

  def self.per_page
    10
  end

  # Disable notification creation & deletion
  def create_notification; end

  def destroy_notification; end

  private

  def set_question_state
    self.question_state = :unanswered
  end
end
