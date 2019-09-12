class AddRepositoryTokenToExercise < ActiveRecord::Migration[6.0]
  def change
    add_column :exercises, :repository_token, :string, limit: 64
    puts "Copying tokens"
    Exercise.all.find_each do |exercise|
      exercise.update(repository_token: exercise.token)
    end
    puts "Copying done"
    change_column :exercises, :repository_token, :string, limit: 64, null: false, unique: true
    add_index :exercises, :repository_token, unique: true
  end
end
