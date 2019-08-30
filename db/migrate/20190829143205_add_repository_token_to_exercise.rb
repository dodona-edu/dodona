class AddRepositoryTokenToExercise < ActiveRecord::Migration[6.0]
  def change
    add_column :exercises, :repository_token, :string, limit: 64
    Exercise.all.in_batches do |batch|
      batch.each_record do |exercise|
        exercise.update(repository_token: exercise.token)
      end
    end
    change_column :exercises, :repository_token, :string, limit: 64, null: false
  end
end
