# == Schema Information
#
# Table name: annotations
#
#  id                  :bigint           not null, primary key
#  annotation_text     :text(16777215)
#  column              :integer
#  columns             :integer
#  line_nr             :integer
#  question_state      :integer
#  rows                :integer          default(1), not null
#  type                :string(255)      default("Annotation"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_id           :integer          not null
#  evaluation_id       :bigint
#  last_updated_by_id  :integer          not null
#  saved_annotation_id :bigint
#  submission_id       :integer
#  thread_root_id      :integer
#  user_id             :integer
#
FactoryBot.define do
  factory :annotation do
    line_nr { 0 }
    annotation_text { 'This code does not contain the right parameters' }
    submission
    user { User.find(2) } # load student fixture

    factory :question, class: 'Question' do
      # Only the submitter can create questions
      before(:create) { |question| question.user = question.submission.user }
    end

    trait :with_evaluation do
      evaluation
    end
  end
end
