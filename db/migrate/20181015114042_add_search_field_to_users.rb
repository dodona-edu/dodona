class AddSearchFieldToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :search, :string, :limit => 4096

    User.find_each do |user|
      user.set_search
      user.save
    end
  end
end
