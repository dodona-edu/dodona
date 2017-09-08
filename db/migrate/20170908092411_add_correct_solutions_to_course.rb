class AddCorrectSolutionsToCourse < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up { add_column :courses, :correct_solutions, :integer }
      dir.down { remove_column :courses, :correct_solutions }
    end
  end
end
