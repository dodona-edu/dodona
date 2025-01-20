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
class SavedAnnotation < ApplicationRecord
  include Filterable
  validates :title, presence: true
  validates :annotation_text, presence: true

  belongs_to :user
  belongs_to :exercise, optional: true
  belongs_to :course, optional: true

  has_many :annotations, dependent: :nullify
  has_many :submissions, through: :annotations

  scope :by_user, ->(user_id) { where user_id: user_id }
  filterable_by :exercise_id, model: Exercise, always_match_nil: true
  filterable_by :course_id, model: Course, always_match_nil: true
  scope :by_filter, ->(filter) { where 'title LIKE ? or annotation_text LIKE ?', "%#{filter}%", "%#{filter}%" }

  scope :order_by_annotations_count, ->(direction) { reorder(annotations_count: direction) }
  scope :order_by_title, ->(direction) { reorder(title: direction) }
  scope :order_by_annotation_text, ->(direction) { reorder(annotation_text: direction) }
end
