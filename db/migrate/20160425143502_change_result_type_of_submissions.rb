class ChangeResultTypeOfSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :status, :integer, index: true
    reversible do |dir|
      change_table :submissions do |t|
        dir.up do
          t.remove_index :result
          t.change :result, :text, default: nil
        end
        dir.down { t.change :result, :integer, default: 0, index: true }
      end
    end
  end
end
