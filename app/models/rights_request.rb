# == Schema Information
#
# Table name: rights_requests
#
#  id               :bigint           not null, primary key
#  user_id          :integer          not null
#  institution_name :string(255)
#  context          :string(255)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class RightsRequest < ApplicationRecord
  belongs_to :user

  after_create :notify_admins

  def approve
    user.update(permission: :staff)
    user.institution.update(name: institution_name) if institution_name.present?
    destroy
    RightsRequestMailer.approved(self).deliver
  end

  def reject
    destroy
    RightsRequestMailer.rejected(self).deliver
  end

  private

  def notify_admins
    RightsRequestMailer.new_request(self).deliver
  end
end
