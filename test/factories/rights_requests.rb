# == Schema Information
#
# Table name: rights_requests
#
#  id               :bigint           not null, primary key
#  context          :text(65535)      not null
#  institution_name :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer          not null
#
FactoryBot.define do
  factory :rights_request do
    user factory: %i[user with_institution]
    institution_name { Faker::University.unique.name.gsub(/[^[:ascii:]]/, '') }
    context { Faker::Lorem.paragraph(sentence_count: 25) }
  end
end
