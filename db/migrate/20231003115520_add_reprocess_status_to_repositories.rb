class AddReprocessStatusToRepositories < ActiveRecord::Migration[7.0]
  def change
    add_column :repositories, :reprocess_queued, :boolean, default: false
    add_column :repositories, :reprocess_running, :boolean, default: false
  end
end
