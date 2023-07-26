class AddRangeToAnnotations < ActiveRecord::Migration[7.0]
  def change
    add_column :annotations, :column, :integer, default: nil
    add_column :annotations, :rows, :integer, default: 1, null: false
    add_column :annotations, :columns, :integer, default: nil
  end
end
