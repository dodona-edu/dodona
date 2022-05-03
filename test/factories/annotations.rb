# == Schema Information
#
# Table name: annotations
#
#  id                  :bigint           not null, primary key
#  line_nr             :integer
#  submission_id       :integer
#  user_id             :integer
#  annotation_text     :text(16777215)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  evaluation_id       :bigint
#  type                :string(255)      default("Annotation"), not null
#  question_state      :integer
#  last_updated_by_id  :integer          not null
#  course_id           :integer          not null
#  saved_annotation_id :bigint
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
  end
end
