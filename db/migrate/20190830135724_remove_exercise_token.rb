class RemoveExerciseToken < ActiveRecord::Migration[6.0]
  def change
    remove_column :exercises, :token
  end
end
