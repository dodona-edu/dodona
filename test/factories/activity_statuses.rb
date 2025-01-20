# == Schema Information
#
# Table name: activity_statuses
#
#  id                          :bigint           not null, primary key
#  accepted                    :boolean          default(FALSE), not null
#  accepted_before_deadline    :boolean          default(FALSE), not null
#  series_id_non_nil           :integer          not null
#  solved                      :boolean          default(FALSE), not null
#  solved_at                   :datetime
#  started                     :boolean          default(FALSE), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  activity_id                 :integer          not null
#  best_submission_deadline_id :integer
#  best_submission_id          :integer
#  last_submission_deadline_id :integer
#  last_submission_id          :integer
#  series_id                   :integer
#  user_id                     :integer          not null
#
FactoryBot.define do
  factory :activity_status
end
