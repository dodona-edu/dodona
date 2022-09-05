# == Schema Information
#
# Table name: saved_annotations
#
#  id                :bigint           not null, primary key
#  title             :string(255)      not null
#  annotation_text   :text(16777215)
#  user_id           :integer          not null
#  exercise_id       :integer          not null
#  course_id         :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  annotations_count :integer          default(0)
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
