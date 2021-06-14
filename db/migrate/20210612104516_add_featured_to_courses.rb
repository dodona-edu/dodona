class AddFeaturedToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :featured, :boolean, default: false, null: false
    add_index :courses, :featured
  end
end
