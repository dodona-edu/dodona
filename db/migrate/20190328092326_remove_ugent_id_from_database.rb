class RemoveUgentIdFromDatabase < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :ugent_id
  end
end
