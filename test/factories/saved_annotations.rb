# == Schema Information
#
# Table name: saved_annotations
#
#  id                :bigint           not null, primary key
#  annotation_text   :text(16777215)
#  annotations_count :integer          default(0)
#  title             :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_id         :integer
#  exercise_id       :integer
#  user_id           :integer          not null
#
FactoryBot.define do
  factory :saved_annotation do
    title { 'Foo' }
    annotation_text { 'Bar' }
    user { nil }
    exercise
    course
  end
end
