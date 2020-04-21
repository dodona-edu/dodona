# == Schema Information
#
# Table name: series
#
#  id                :integer          not null, primary key
#  course_id         :integer
#  name              :string(255)
#  description       :text(65535)
#  visibility        :integer
#  order             :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deadline          :datetime
#  access_token      :string(255)
#  indianio_token    :string(255)
#  progress_enabled  :boolean          default(TRUE), not null
#  exercises_visible :boolean          default(TRUE), not null
#

FactoryBot.define do
  factory :series do
    sequence(:name) { |n| "Series #{n}" }
    description { Faker::TvShows::DrWho.quote }
    visibility { :open }
    course

    trait :hidden do
      visibility { :hidden }
    end

    transient do
      exercise_count { 0 }
      exercise_repositories do
        create_list(:repository, 2, :git_stubbed) if exercise_count.positive?
      end

      exercise_submission_count { 0 }
      exercise_submission_users do
        create_list :user, 2, courses: [course] if exercise_submission_count.positive?
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
      series.reload
    end

    trait :with_submissions do
      exercise_count { 2 }
      exercise_submission_count { 2 }
    end
  end
end
