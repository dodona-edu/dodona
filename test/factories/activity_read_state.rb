FactoryBot.define do
  factory :activity_read_state do
    activity { content_page }
    user { User.find(2) } # load student fixture
  end
end
