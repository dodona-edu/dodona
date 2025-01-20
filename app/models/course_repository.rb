# == Schema Information
#
# Table name: course_repositories
#
#  id            :bigint           not null, primary key
#  course_id     :integer          not null
#  repository_id :integer          not null
#

class CourseRepository < ApplicationRecord
  belongs_to :course
  belongs_to :repository
end
