# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  description       :text(4294967295)
#  enabled_questions :boolean          default(TRUE), not null
#  featured          :boolean          default(FALSE), not null
#  moderated         :boolean          default(FALSE), not null
#  name              :string(255)
#  registration      :integer          default("open_for_institutional_users")
#  search            :string(4096)
#  secret            :string(255)
#  teacher           :string(255)
#  visibility        :integer          default("visible_for_all")
#  year              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  institution_id    :bigint
#
# Indexes
#
#  index_courses_on_featured        (featured)
#  index_courses_on_institution_id  (institution_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#

FactoryBot.define do
  factory :course do
    name { "#{Faker::Hacker.adjective.titlecase} Programming" }
    description { Faker::Hacker.say_something_smart }
    visibility { 'visible_for_all' }
    registration { 'open_for_all' }
    moderated { false }
    teacher { "Prof. #{Faker::Name.first_name} #{Faker::Name.last_name}" }

    transient do
      series_count { 0 }
      activities_per_series { 0 }
      exercises_per_series { nil }
      content_pages_per_series { nil }
      submissions_per_exercise { 0 }
      start_year { Time.zone.today.year }
    end

    year { "#{start_year}-#{start_year + 1}" }

    after :create do |course, e|
      e.series_count.times do
        create :series,
               course: course,
               activity_count: e.activities_per_series,
               exercise_count: e.exercises_per_series,
               content_page_count: e.content_pages_per_series,
               exercise_submission_count: e.submissions_per_exercise
      end
    end
  end
end
