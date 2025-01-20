# == Schema Information
#
# Table name: users
#
#  id                   :integer          not null, primary key
#  email                :string(255)
#  first_name           :string(255)
#  lang                 :string(255)      default("nl")
#  last_name            :string(255)
#  open_questions_count :integer          default(0), not null
#  permission           :integer          default("student")
#  search               :string(4096)
#  seen_at              :datetime
#  sign_in_at           :datetime
#  theme                :integer          default("system"), not null
#  time_zone            :string(255)      default("Brussels")
#  token                :string(255)
#  username             :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  institution_id       :bigint
#
# Indexes
#
#  index_users_on_institution_id  (institution_id)
#  index_users_on_token           (token)
#  index_users_on_username        (username)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#

FactoryBot.define do
  factory :user, aliases: [:student] do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.unique.user_name(specifier: 5..32) }
    email { "#{first_name}.#{last_name}.#{username}@ugent.be".downcase.gsub(' ', '_') }
    permission { :student }

    trait :with_institution do
      institution
    end
  end

  factory :zeus, parent: :user do
    permission { :zeus }
  end

  factory :staff, parent: :user do
    permission { :staff }
  end

  factory :temporary_user, parent: :user do
    username { nil }
    institution { nil }
  end
end
