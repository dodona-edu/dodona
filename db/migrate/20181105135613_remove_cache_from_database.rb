class RemoveCacheFromDatabase < ActiveRecord::Migration[5.2]
  def change
    remove_column :series_memberships, :users_correct
    remove_column :series_memberships, :users_attempted
    remove_column :courses, :correct_solutions
  end
end
