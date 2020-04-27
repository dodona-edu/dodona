FactoryBot.define do
  factory :activity_read_state do
    activity { content_page }
    user
  end
end
