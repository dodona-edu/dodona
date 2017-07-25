FactoryGirl.define do
  factory :user do
    first_name Faker::Name.first_name
    last_name Faker::Name.last_name
    username { "#{first_name[0]}#{last_name[0..7]}".downcase }
    ugent_id Faker::Number(8).to_s
    email { "#{first_name}.#{last_name}@UGent.BE" }
    permission :student

    transient do
      course_count 1
    end

    after(:create) do |user, evaluator|
      create_list(:course, evaluator.course_count, user: user)
    end
  end
end
