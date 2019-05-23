class AddModeratedToCourse < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :moderated, :boolean, null: false, default: false
    Course.where(registration: :open_for_institution).update_all(moderated: true, registration: :open_for_all)
    Course.where(visibility: :visible_for_institution).update_all(visibility: :hidden)
  end
end
