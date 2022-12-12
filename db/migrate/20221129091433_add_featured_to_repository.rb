class AddFeaturedToRepository < ActiveRecord::Migration[7.0]
  def change
    add_column :repositories, :featured, :boolean, default: false
  end
end
