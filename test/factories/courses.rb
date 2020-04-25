# == Schema Information
#
# Table name: courses
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  year           :string(255)
#  secret         :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  description    :text(65535)
#  visibility     :integer
#  registration   :integer
#  color          :integer
#  teacher        :string(255)      default("")
#  institution_id :bigint
#  search         :string(4096)
#  moderated      :boolean          default(FALSE), not null
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
      submissions_per_exercise { 0 }
      start_year { Time.zone.today.year }
    end

    year { "#{start_year}-#{start_year + 1}" }

    after :create do |course, e|
      e.series_count.times do
        create :series, course: course, activity_count: e.activities_per_series, exercise_submission_count: e.submissions_per_exercise
      end
    end
  end
end
