class RemoveActivitiesJob < ApplicationJob
  # permanently remove activities that match all of the following criteria:
  # - status is 'removed'
  # - updated_at is more than 1 month ago
  # - one of the following is true:
  #   - draft is true (never published)
  #   - series_memberships is empty and less then 25 submissions and latest submission is more than 1 month ago
  #
  # Destroy is called on each activity individually to ensure that callbacks are run
  # This means the activity will be removed from any series, evaluations it is a member of
  # and any submissions will be removed
  queue_as :cleaning

  def perform
    ContentPage.where(status: 'removed').where('updated_at < ?', 1.month.ago).find_each do |activity|
      if activity.draft? || activity.series_memberships.empty?
        # destroy series memberships first explicitly, as they are dependent: :restrict_with_error
        activity.series_memberships.destroy_all

        activity.destroy
      end
    end

    Exercise.where(status: 'removed').where('updated_at < ?', 1.month.ago).find_each do |activity|
      if activity.draft? ||
         (activity.series_memberships.empty? &&
           (activity.submissions.empty? ||
             (activity.submissions.count < 25 && activity.submissions.reorder(:created_at).last.created_at < 1.month.ago)))
        # destroy submissions first explicitly, as they are dependent: :restrict_with_error
        activity.submissions.destroy_all

        # destroy series memberships first explicitly, as they are dependent: :restrict_with_error
        activity.series_memberships.destroy_all

        activity.destroy
      end
    end

    # rerun this job in 1 month
    RemoveActivitiesJob.set(wait: 1.month).perform_later
  end
end
