# == Schema Information
#
# Table name: score_items
#
#  id                     :bigint           not null, primary key
#  evaluation_exercise_id :bigint           not null
#  maximum                :decimal(10, )    not null
#  name                   :string(255)      not null
#  visible                :boolean          default(TRUE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
FactoryBot.define do
  factory :score_template do
    evaluation_exercise { nil }
    maximum { '9.99' }
    name { 'MyString' }
    visible { false }
  end
end
