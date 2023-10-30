task :destroy_removed_activities => :environment do
  # permanently remove activities that match the following criteria:
  # - status is 'removed'
  # - updated_at is more than 1 month ago
  # - one of the following is true:
  #   - draft is true (never published)
  #   - series_memberships is empty and less then 25 submissions and latest submission is more than 1 month ago

  ContentPage.where(status: 'removed').where('updated_at < ?', 1.month.ago).find_each do |activity|
    if activity.draft? || activity.series_memberships.empty?
      activity.destroy
    end
  end

  Exercise.where(status: 'removed').where('updated_at < ?', 1.month.ago).find_each do |activity|
    if activity.draft? ||
      ( activity.series_memberships.empty? &&
        ( activity.submissions.empty? ||
          (activity.submissions.count < 25 && activity.submissions.order(:created_at).last.created_at < 1.month.ago)))
      activity.destroy
    end
  end
end
