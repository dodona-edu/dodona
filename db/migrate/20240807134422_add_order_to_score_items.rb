class AddOrderToScoreItems < ActiveRecord::Migration[7.1]
  def change
    add_column :score_items, :order, :integer
  end
end
