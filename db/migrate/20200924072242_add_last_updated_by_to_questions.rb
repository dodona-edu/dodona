class AddLastUpdatedByToQuestions < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up {
        add_reference :annotations, :last_updated_by, type: :integer
        add_foreign_key :annotations, :users, column: :last_updated_by_id
        Annotation.update_all('last_updated_by_id = user_id')
        change_column_null :annotations, :last_updated_by_id, false
      }
      dir.down {
        remove_column :annotations, :last_updated_by_id
      }
    end
  end
end
