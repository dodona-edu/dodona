# == Schema Information
#
# Table name: exports
#
#  id         :bigint           not null, primary key
#  user_id    :integer
#  status     :integer          default("0"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :export do
    user
  end
end
