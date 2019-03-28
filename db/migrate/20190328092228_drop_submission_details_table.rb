class DropSubmissionDetailsTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :submission_details
  end
end
