FactoryGirl.define do
  factory :exercise do
    sequence(:name_nl) { |n| "Oefening #{n}" }
    sequence(:name_en) { |n| "Exercise #{n}" }
    visibility :open
    status :ok

    sequence(:path) { |n| "exercise#{n}" }

    repository
    judge
  end
end
