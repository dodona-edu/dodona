# == Schema Information
#
# Table name: evaluations
#
#  id         :bigint           not null, primary key
#  series_id  :integer
#  released   :boolean          default(FALSE), not null
#  deadline   :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :evaluation do
    series { create :series, deadline: DateTime.now - 1.minute }
    deadline { series.deadline || (DateTime.now - 1.minute) }
    released { false }
    exercises { series.exercises }
    users { series.course.submissions.where(exercise: exercises).map(&:user).uniq }

    transient do
      user_count { 1 }
    end

    trait :released do
      released { true }
    end

    trait :with_submissions do
      series do
        s = create :series, exercise_count: 2, deadline: DateTime.now
        users = create_list :user, user_count
        users.each do |u|
          s.course.enrolled_members << u
          s.exercises.each do |e|
            create :correct_submission, user: u, exercise: e, course: s.course, created_at: s.deadline - 1.hour
          end
        end
        s
      end
    end
  end
end
