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
#  visibility     :integer          default("visible_for_all")
#  registration   :integer          default("open_for_all")
#  color          :integer
#  teacher        :string(255)      default("")
#  institution_id :bigint(8)
#  search         :string(4096)
#  moderated      :boolean          default(FALSE), not null
#

FactoryBot.define do
  factory :course do
    name { "#{Faker::Hacker.adjective.titlecase} Programming" }
    description { Faker::Hacker.say_something_smart }
    visibility {'visible_for_all'}
    registration {'open_for_all'}
    moderated {false}
    teacher { "Prof. #{Faker::Name.first_name} #{Faker::Name.last_name}" }

    transient do
      series_count { 0 }
      exercises_per_series { 0 }
      start_year { Time.zone.today.year }
    end

    year { "#{start_year}-#{start_year + 1}" }

    after :create do |course, e|
      e.series_count.times do
        create :series, course: course, exercise_count: e.exercises_per_series
      end
    end
  end
end
