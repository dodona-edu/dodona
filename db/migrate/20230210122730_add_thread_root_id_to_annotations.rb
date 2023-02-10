class AddThreadRootIdToAnnotations < ActiveRecord::Migration[7.0]
  def change
    add_column :annotations, :thread_root_id, :integer, null: true, default: nil
  end
end
