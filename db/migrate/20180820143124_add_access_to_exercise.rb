class AddAccessToExercise < ActiveRecord::Migration[5.1]
  def change
    add_column :exercises, :access, :integer, null: false, default: 0

    Exercise.all.each do |ex|
      if ex.visibility == 0
        ex.update(access: :public)
      else
        ex.update(access: :private)
      end
    end

    remove_column :exercises, :visibility
  end
end
