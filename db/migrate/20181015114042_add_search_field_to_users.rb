class AddSearchFieldToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :search, :string

    User.all.each do |user|
      user.update(search: "#{user.username || ''} #{user.first_name || ''} #{user.last_name}")
    end
  end
end
