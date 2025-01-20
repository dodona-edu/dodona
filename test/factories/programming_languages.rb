# == Schema Information
#
# Table name: programming_languages
#
#  id            :bigint           not null, primary key
#  editor_name   :string(255)      not null
#  extension     :string(255)      not null
#  icon          :string(255)
#  name          :string(255)      not null
#  renderer_name :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :programming_language do
    name { "#{Faker::ProgrammingLanguage.name}#{Faker::Number.unique.positive}" }
    editor_name { name }
    renderer_name { name }
    extension { name }
  end
end
