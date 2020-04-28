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

    after :create do |a|
      exercise_ids = a.series.exercises.map(&:id).uniq
      user_ids = a.series.course.submissions.where(exercise_id: exercise_ids).map(&:user_id).uniq
      a.create_review_session(exercise_ids, user_ids)
    end
  end

  trait :released do
    released { true }
  end
end
