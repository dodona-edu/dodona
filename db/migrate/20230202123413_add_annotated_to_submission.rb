class AddAnnotatedToSubmission < ActiveRecord::Migration[7.0]
  def change
    add_column :submissions, :annotated, :boolean, default: false, null: false
  end
end
