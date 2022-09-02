# == Schema Information
#
# Table name: exports
#
#  id         :bigint           not null, primary key
#  user_id    :integer
#  status     :integer          default("started"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :export do
    user { User.find(2) } # load student fixture
  end
end
