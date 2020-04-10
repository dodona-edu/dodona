class AddLineCountToSubmission < ActiveRecord::Migration[6.0]
  def change
    add_column :submissions, :line_count, :integer
  end
end
