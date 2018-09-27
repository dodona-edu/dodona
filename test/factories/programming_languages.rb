FactoryBot.define do
  factory :programming_language do
    name { Faker::ProgrammingLanguage.unique.name }
    editor_name { name }
    extension { name }
  end
end
