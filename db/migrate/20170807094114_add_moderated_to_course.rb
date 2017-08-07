class AddModeratedToCourse < ActiveRecord::Migration[5.0]
  def change
    add_column :courses, :moderated, :boolean
  end
end
