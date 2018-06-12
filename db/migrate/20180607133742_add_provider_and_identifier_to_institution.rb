class AddProviderAndIdentifierToInstitution < ActiveRecord::Migration[5.1]
  def change
    change_table :institutions do |t|
      t.integer :provider
      t.string  :identifier
    end
  end
end
