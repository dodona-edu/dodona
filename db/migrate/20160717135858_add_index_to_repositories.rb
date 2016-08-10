class AddIndexToRepositories < ActiveRecord::Migration[5.0]
  def change
    add_index :repositories, :path, unique: true
  end
end
