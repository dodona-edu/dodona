class AddSubmissionsToActivityStatus < ActiveRecord::Migration[6.0]
  def change
    add_column :activity_statuses, :last_submission_id, :integer
    add_column :activity_statuses, :last_submission_deadline_id, :integer
    add_column :activity_statuses, :best_submission_id, :integer
    add_column :activity_statuses, :best_submission_deadline_id, :integer
    execute 'TRUNCATE TABLE activity_statuses'
  end
end
