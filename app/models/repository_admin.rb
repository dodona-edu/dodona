# == Schema Information
#
# Table name: repository_admins
#
#  id            :integer         not null, primary key
#  repository_id :integer         not null
#  user_id       :integer         not null
class RepositoryAdmin < ApplicationRecord
  belongs_to :user
  belongs_to :repository
end
