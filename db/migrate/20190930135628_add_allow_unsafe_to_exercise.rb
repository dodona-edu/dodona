class AddAllowUnsafeToExercise < ActiveRecord::Migration[6.0]
  def change
    add_column :exercises, :allow_unsafe, :boolean, default: false, null: false
  end
end
