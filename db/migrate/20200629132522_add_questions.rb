class AddQuestions < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up {
        add_column :annotations, :type, :string, default: "Annotation", null: false
        add_column :annotations, :question_state, :integer
      }
      dir.down {
        remove_column :annotations, :type
        remove_column :annotations, :question_state
      }
    end
  end
end
