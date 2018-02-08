# == Schema Information
#
# Table name: series
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  name           :string(255)
#  description    :text(65535)
#  visibility     :integer
#  order          :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deadline       :datetime
#  access_token   :string(255)
#  indianio_token :string(255)
#

FactoryBot.define do
  factory :series do
    sequence(:name) { |n| "Series #{n}" }
    description Faker::DrWho.quote
    visibility :open
    course

    trait :hidden do
      visibility :hidden
    end

    transient do
      exercise_count 0
      exercise_repositories do
        create_list(:repository, 2, :git_stubbed) if exercise_count.positive?
      end

      exercise_submission_count 0
      exercise_submission_users do
        if exercise_submission_count.positive?
          create_list :user, 2, courses: [course]
        end
      end
    end

    after :create do |series, e|
      e.exercise_count.times do
        create :exercise,
               repository: e.exercise_repositories.sample,
               series: [series],
               submission_count: e.exercise_submission_count,
               submission_users: e.exercise_submission_users
      end
    end

    trait :with_submissions do
      exercise_count 10
      exercise_submission_count 3
    end
  end
end
