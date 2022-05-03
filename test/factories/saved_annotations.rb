# == Schema Information
#
# Table name: saved_annotations
#
#  id              :bigint           not null, primary key
#  title           :string(255)      not null
#  annotation_text :text(16777215)
#  user_id         :integer          not null
#  exercise_id     :integer          not null
#  course_id       :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :saved_annotation do
    annotation_text { 'MyText' }
    user { nil }
    exercise { nil }
    course { nil }
  end
end
