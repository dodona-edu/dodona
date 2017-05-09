class SplitSubmissions < ActiveRecord::Migration[5.0]
  def self.up
    create_table :submission_details do |t|
      t.text :code
      t.binary :result, limit: 2.megabyte
    end

    execute "INSERT INTO submission_details (id, code, result) SELECT id, code, result FROM submissions;"

    remove_column :submissions, :result
    remove_column :submissions, :code
  end

  def self.down
    add_column :submissions, :result, :binary, limit: 2.megabyte
    add_column :submissions, :code, :text

    execute "UPDATE submissions, submission_details SET submissions.result = submission_details.result, submissions.code = submission_details.code WHERE submissions.id = submission_details.id"

    drop_table :submission_details
  end
end
