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
#  anonymous  :boolean          default(FALSE), not null
#
FactoryBot.define do
  factory :evaluation do
    series { create :series, deadline: DateTime.now - 1.minute }
    deadline { series.deadline || (DateTime.now - 1.minute) }
    released { false }
    exercises { series.exercises }
    users { series.course.submissions.where(exercise: exercises).map(&:user).uniq }
    anonymous { false }

    transient do
      user_count { 1 }
    end

    trait :released do
      released { true }
    end

    trait :is_anonymous do
      anonymous { true }
    end
  end
end
