class AddProviderToInstitution < ActiveRecord::Migration[5.1]
  def change
    change_table :institutions do |t|
      t.integer :provider
    end
  end
end
