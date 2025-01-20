# == Schema Information
#
# Table name: course_repositories
#
#  id            :bigint           not null, primary key
#  course_id     :integer          not null
#  repository_id :integer          not null
#
# Indexes
#
#  fk_rails_4d1393e517                                       (repository_id)
#  index_course_repositories_on_course_id_and_repository_id  (course_id,repository_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (repository_id => repositories.id)
#

class CourseRepository < ApplicationRecord
  belongs_to :course
  belongs_to :repository
end
