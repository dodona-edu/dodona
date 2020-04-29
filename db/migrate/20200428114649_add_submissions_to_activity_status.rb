class AddSubmissionsToActivityStatus < ActiveRecord::Migration[6.0]
  def change
    # since we need to nuke the table after this is done, we might as well start
    # with it to make adding the columns faster
    execute 'TRUNCATE TABLE activity_statuses'
    add_column :activity_statuses, :last_submission_id, :integer
    add_column :activity_statuses, :last_submission_deadline_id, :integer
    add_column :activity_statuses, :best_submission_id, :integer
    add_column :activity_statuses, :best_submission_deadline_id, :integer
    execute 'TRUNCATE TABLE activity_statuses'
  end
end
