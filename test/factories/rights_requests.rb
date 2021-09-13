# == Schema Information
#
# Table name: rights_requests
#
#  id               :bigint           not null, primary key
#  user_id          :integer          not null
#  institution_name :string(255)
#  context          :text(65535)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do
  factory :rights_request do
    association :user, :with_institution
    institution_name { Faker::University.unique.name.gsub(/[^[:ascii:]]/, '') }
    context { Faker::Lorem.paragraph(sentence_count: 25) }
  end
end
