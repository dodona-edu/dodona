class AddAccessTokenToExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :access_token, :string, limit: 16
    Exercise.find_each(&:generate_access_token)
    change_column :exercises, :access_token, :string, null: false, limit: 16
  end
end
