class AddTeacherToCourse < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up { add_column :courses, :teacher, :string, default: ""}
      dir.down { remove_column :courses, :teacher }
    end
  end
end
