# == Schema Information
#
# Table name: reviews
#
#  id                 :bigint           not null, primary key
#  submission_id      :integer
#  review_session_id  :bigint
#  review_user_id     :bigint
#  review_exercise_id :bigint
#  completed          :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :review_session do
    series { create :series, :with_submissions, deadline: DateTime.now + 1.hour }
    deadline { series.deadline }
    released { false }
    exercises { series.exercises }
    users { series.course.submissions.where(exercise: exercises).map(&:user).uniq }
  end

  trait :released do
    released { true }
  end
end
