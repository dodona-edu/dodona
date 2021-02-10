# == Schema Information
#
# Table name: rubrics
#
#  id                     :bigint           not null, primary key
#  evaluation_exercise_id :bigint           not null
#  maximum                :decimal(5, 2)    not null
#  name                   :string(255)      not null
#  visible                :boolean          default(TRUE), not null
#  description            :text(65535)
#  last_updated_by_id     :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
FactoryBot.define do
  factory :rubric do
    sequence(:name) { |n| "Rubric #{n}" }

    evaluation_exercise
    maximum { '10.00' }
    visible { true }
    last_updated_by { create :user }
    description { Faker::Lorem.unique.sentence }
  end
end
