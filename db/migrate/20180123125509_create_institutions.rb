class CreateInstitutions < ActiveRecord::Migration[5.1]
  def change
    create_table :institutions do |t|
      t.string :name
      t.string :short_name
      t.string :logo
      t.string :sso_url
      t.string :slo_url
      t.text :certificate

      t.timestamps
    end
  end
end
