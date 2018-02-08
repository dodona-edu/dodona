class AddEntityIdToInstitutions < ActiveRecord::Migration[5.1]
  def change
    add_column :institutions, :entity_id, :string
  end
end
