class RemoveLineCount < ActiveRecord::Migration[6.0]
  def change
    remove_column :submissions, :line_count
  end
end
