class AddColorToCourse < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        #add_column :courses, :color, :integer
        Course.all.each do |c|
          c.update(color: Course.colors.keys.sample)
        end
      end
      dir.down { remove_column :courses, :color }
    end
  end
end
