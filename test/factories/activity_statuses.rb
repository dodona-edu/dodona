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
# Indexes
#
#  fk_rails_1bc42c2178                                            (series_id)
#  index_activity_statuses_on_accepted_and_user_id_and_series_id  (accepted,user_id,series_id)
#  index_activity_statuses_on_activity_id                         (activity_id)
#  index_activity_statuses_on_started_and_user_id_and_series_id   (started,user_id,series_id)
#  index_as_on_started_and_user_and_last_submission               (started,user_id,last_submission_id)
#  index_as_on_user_and_series_and_last_submission                (user_id,series_id,last_submission_id)
#  index_on_user_id_series_id_non_nil_activity_id                 (user_id,series_id_non_nil,activity_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id) ON DELETE => cascade
#  fk_rails_...  (series_id => series.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :activity_status
end
