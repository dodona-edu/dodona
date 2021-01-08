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
    series { create :series, :with_submissions, deadline: DateTime.now - 1.hour }
    deadline { series.deadline }
    released { false }
    exercises { series.exercises }
    users { series.course.submissions.where(exercise: exercises).map(&:user).uniq }
  end

  trait :released do
    released { true }
  end
end
