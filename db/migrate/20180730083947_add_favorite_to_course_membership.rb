class AddFavoriteToCourseMembership < ActiveRecord::Migration[5.1]
  def change
    add_column :course_memberships, :favorite, :boolean, default: false
  end
end
