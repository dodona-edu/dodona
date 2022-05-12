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
class SavedAnnotation < ApplicationRecord
  validates :title, presence: true, uniqueness: { scope: %i[user_id exercise_id course_id] }
  validates :annotation_text, presence: true

  belongs_to :user
  belongs_to :exercise
  belongs_to :course

  has_many :annotations, dependent: :nullify

  scope :by_user, ->(user_id) { where user_id: user_id }
  scope :by_course, ->(course_id) { where course_id: course_id }
  scope :by_exercise, ->(exercise_id) { where exercise_id: exercise_id }
  scope :by_filter, ->(filter) { where 'title LIKE ?', "%#{filter}%" }
end
