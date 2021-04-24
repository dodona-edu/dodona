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
FactoryBot.define do
  factory :rights_request do
    user_id { nil }
    institution_name { 'MyString' }
    context { 'MyString' }
  end
end
