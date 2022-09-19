class AddAnnotationsCountToSavedAnnotations < ActiveRecord::Migration[7.0]
  def change
    add_column :saved_annotations, :annotations_count, :integer, default: 0
  end
end
