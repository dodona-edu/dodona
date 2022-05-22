# == Schema Information
#
# Table name: repository_admins
#
#  id            :bigint           not null, primary key
#  repository_id :integer          not null
#  user_id       :integer          not null
#

class RepositoryAdmin < ApplicationRecord
  before_destroy :at_least_one_admin_per_repository

  belongs_to :user
  belongs_to :repository

  def at_least_one_admin_per_repository
    return if RepositoryAdmin.where(repository_id:).count > 1

    errors.add :base, 'Cannot delete last repository admin'
    throw(:abort)
  end
end
