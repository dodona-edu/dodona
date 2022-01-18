class AddCategoryToInstitutions < ActiveRecord::Migration[6.1]
  def change
    add_column :institutions, :category, :integer, default: 0, null: false
  end
end
