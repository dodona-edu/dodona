class AddOrderToSeries < ActiveRecord::Migration[5.2]
  def change
    Course.find_each do |c|
      Series.where(course_id: c.id).each_with_index do |s, i|
        s.update(order: i)
      end
    end

    change_column :series, :order, :integer, default: 0, null: false
  end
end
