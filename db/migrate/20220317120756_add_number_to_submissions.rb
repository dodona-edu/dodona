class AddNumberToSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_column :submissions, :number, :integer
  end
end
