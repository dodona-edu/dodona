# == Schema Information
#
# Table name: evaluation_users
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  evaluation_id :bigint
#  user_id       :integer
#
# Indexes
#
#  index_evaluation_users_on_evaluation_id              (evaluation_id)
#  index_evaluation_users_on_user_id                    (user_id)
#  index_evaluation_users_on_user_id_and_evaluation_id  (user_id,evaluation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (evaluation_id => evaluations.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :evaluation_user do
    evaluation
    user
  end
end
