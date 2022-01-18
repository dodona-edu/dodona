class AddStatusToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :status, :integer
  end
end
