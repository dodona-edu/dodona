# == Schema Information
#
# Table name: programming_languages
#
#  id          :bigint(8)        not null, primary key
#  name        :string(255)      not null
#  editor_name :string(255)      not null
#  extension   :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :programming_language do
    name { "#{Faker::ProgrammingLanguage.unique.name}#{Faker::Number.unique.positive}" }
    editor_name { name }
    extension { name }
  end
end
