class AddProviderToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :provider, :string
  end
end
