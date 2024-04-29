class AddUniqueToRepositoryRemote < ActiveRecord::Migration[7.1]
  def change
    add_index :repositories, :remote, unique: true
  end
end
