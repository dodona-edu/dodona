# == Schema Information
#
# Table name: courses
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  year        :string(255)
#  secret      :string(255)
#  open        :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text(65535)
#

require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  test 'factory' do
    create :course
  end
end
