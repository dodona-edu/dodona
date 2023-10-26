class AddDraftToActivities < ActiveRecord::Migration[7.0]
  def change
    add_column :activities, :draft, :boolean, default: false
  end
end
