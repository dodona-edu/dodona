# == Schema Information
#
# Table name: notifications
#
#  id              :bigint           not null, primary key
#  message         :string(255)      not null
#  read            :boolean          default(FALSE), not null
#  user_id         :integer          not null
#  notifiable_type :string(255)
#  notifiable_id   :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :notification do
  end
end
