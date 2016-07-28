class ExtendSubmission < ActiveRecord::Migration[5.0]
  def change
    rename_column :submissions, :result, :summary
    change_column :submissions, :summary, :string
    add_column :submissions, :result, :binary, limit: 2.megabyte
    add_column :submissions, :accepted, :boolean, default: false

    add_index :submissions, :accepted
    add_index :submissions, :status
  end
end
