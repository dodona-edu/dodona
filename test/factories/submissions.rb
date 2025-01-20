# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  accepted    :boolean          default(FALSE)
#  annotated   :boolean          default(FALSE), not null
#  fs_key      :string(24)
#  number      :integer
#  status      :integer
#  summary     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  course_id   :integer
#  exercise_id :integer
#  series_id   :integer
#  user_id     :integer
#
# Indexes
#
#  ex_st_co_idx                      (exercise_id,status,course_id)
#  ex_us_ac_cr_index                 (exercise_id,user_id,accepted,created_at)
#  ex_us_st_cr_index                 (exercise_id,user_id,status,created_at)
#  index_submissions_on_accepted     (accepted)
#  index_submissions_on_course_id    (course_id)
#  index_submissions_on_exercise_id  (exercise_id)
#  index_submissions_on_fs_key       (fs_key) UNIQUE
#  index_submissions_on_status       (status)
#  index_submissions_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (exercise_id => activities.id)
#  fk_rails_...  (user_id => users.id)
#

FactoryBot.define do
  factory :submission do
    code { Faker::Lorem.paragraph }
    evaluate { false }
    skip_rate_limit_check { true }

    user { User.find(3) } # load student user fixture
    exercise { Exercise.find(1) } # load python exercise fixture

    initialize_with { new(attributes) }

    trait :generated_user do
      user
    end

    trait :generated_exercise do
      exercise
    end

    trait :correct do
      status { 'correct' }
      summary { 'Good job!' }
      accepted { true }
    end

    trait :wrong do
      status { 'wrong' }
      summary { 'You used the wrong programming language' }
      accepted { false }
    end

    trait :within_course do
      course
    end

    factory :wrong_submission, traits: [:wrong]
    factory :correct_submission, traits: [:correct]
    factory :course_submission, traits: [:within_course]

    trait :rate_limited do
      skip_rate_limit_check { false }
    end
  end
end
