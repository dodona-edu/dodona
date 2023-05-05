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
#  thread_root_id      :integer
#  column              :integer
#  rows                :integer          default(1), not null
#  columns             :integer
#
class Strikethrough < Annotation
  validates :annotation_text, absence: true
end
