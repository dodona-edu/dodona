FactoryBot.define do
  factory :activity do
    initialize_with { create :exercise }
  end
end
