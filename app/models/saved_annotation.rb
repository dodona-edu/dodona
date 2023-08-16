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
class SavedAnnotation < ApplicationRecord
  validates :title, presence: true, uniqueness: { scope: %i[user_id exercise_id course_id] }
  validates :annotation_text, presence: true

  belongs_to :user
  belongs_to :exercise
  belongs_to :course

  has_many :annotations, dependent: :nullify
  has_many :submissions, through: :annotations

  scope :by_user, ->(user_id) { where user_id: user_id }
  scope :by_course, ->(course_id) { where course_id: course_id }
  scope :by_exercise, ->(exercise_id) { where exercise_id: exercise_id }
  scope :by_filter, ->(filter) { where 'title LIKE ? or annotation_text LIKE ?', "%#{filter}%", "%#{filter}%" }

  scope :order_by_annotations_count, ->(direction) { reorder(annotations_count: direction) }
  scope :order_by_title, ->(direction) { reorder(title: direction) }
  scope :order_by_annotation_text, ->(direction) { reorder(annotation_text: direction) }
end
