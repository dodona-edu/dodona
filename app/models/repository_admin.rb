# == Schema Information
#
# Table name: repository_admins
#
#  id            :bigint           not null, primary key
#  repository_id :integer          not null
#  user_id       :integer          not null
#
# Indexes
#
#  fk_rails_6b59ad362c                                   (user_id)
#  index_repository_admins_on_repository_id_and_user_id  (repository_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (repository_id => repositories.id)
#  fk_rails_...  (user_id => users.id)
#

class RepositoryAdmin < ApplicationRecord
  before_destroy :at_least_one_admin_per_repository

  belongs_to :user
  belongs_to :repository

  def at_least_one_admin_per_repository
    return if RepositoryAdmin.where(repository_id: repository_id).count > 1

    errors.add :base, 'Cannot delete last repository admin'
    throw(:abort)
  end
end
