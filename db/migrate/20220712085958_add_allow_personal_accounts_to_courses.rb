class AddAllowPersonalAccountsToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :allow_personal_accounts, :boolean, default: false, null: false
  end
end
