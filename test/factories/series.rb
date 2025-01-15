# == Schema Information
#
# Table name: series
#
#  id                       :integer          not null, primary key
#  access_token             :string(255)
#  activities_count         :integer
#  activities_visible       :boolean          default(TRUE), not null
#  activity_numbers_enabled :boolean          default(FALSE), not null
#  deadline                 :datetime
#  description              :text(4294967295)
#  name                     :string(255)
#  order                    :integer          default(0), not null
#  progress_enabled         :boolean          default(TRUE), not null
#  visibility               :integer
#  visibility_start         :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  course_id                :integer
#

FactoryBot.define do
  factory :series do
    sequence(:name) { |n| "Series #{n}" }
    description { Faker::TvShows::DrWho.quote }
    visibility { :open }
    course { Course.find(1) } # load course 1 fixture

    trait :generated_course do
      course
    end

    trait :hidden do
      visibility { :hidden }
    end

    transient do
      activity_count { 0 }
      exercise_count { nil }
      content_page_count { nil }
      exercise_submission_count { 0 }
      exercise_submission_users do
        create_list :user, 2, courses: [course] if exercise_submission_count.positive?
      end
    end

    after :create do |series, e|
      content_page_count = e.content_page_count || (e.activity_count / 2)
      exercise_count = e.exercise_count || (e.activity_count - content_page_count)
      exercise_count.times do
        create :exercise,
               series: [series],
               submission_count: e.exercise_submission_count,
               submission_users: e.exercise_submission_users
      end
      content_page_count.times do
        create :content_page,
               series: [series]
      end
      series.reload
    end

    trait :with_submissions do
      exercise_count { 2 }
      exercise_submission_count { 2 }
    end
  end
end
