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
#
FactoryBot.define do
  factory :annotation do
    line_nr { 0 }
    annotation_text { 'This code does not contain the right parameters' }
    submission
    user

    factory :question, class: 'Question' do
    end
  end
end
