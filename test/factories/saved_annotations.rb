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
# Indexes
#
#  index_saved_annotations_on_course_id    (course_id)
#  index_saved_annotations_on_exercise_id  (exercise_id)
#  index_saved_annotations_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (exercise_id => activities.id)
#  fk_rails_...  (user_id => users.id)
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
