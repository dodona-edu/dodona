class AddGeneratedNameToInstitutions < ActiveRecord::Migration[6.0]
  def change
    add_column :institutions, :generated_name, :boolean, default: true, null: false
    Institution.where.not(name: 'n/a').update_all(generated_name: false)
  end
end
