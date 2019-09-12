class AddExercisesVisibleToSeries < ActiveRecord::Migration[5.2]
  def change
    add_column :series, :exercises_visible, :boolean, null: false, default: true
  end
end
