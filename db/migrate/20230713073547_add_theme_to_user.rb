class AddThemeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :theme, :integer, null: false, default: 0
  end
end
