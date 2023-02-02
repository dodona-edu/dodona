class AddReleasedAnnotationCountToSubmissions < ActiveRecord::Migration[7.0]
  def self.up
    add_column :submissions, :released_annotation_count, :integer, null: false, default: 0

    Annotation.counter_culture_fix_counts
  end

  def self.down
    remove_column :submissions, :released_annotation_count
  end
end
