class AddUniqueIndexToEvaluations < ActiveRecord::Migration[7.0]
  def change
    add_index :evaluations, :series_id, unique: true, name: 'index_evaluations_on_unique_series_id'
    remove_index :evaluations, :series_id, name: 'index_evaluations_on_series_id'
  end
end
