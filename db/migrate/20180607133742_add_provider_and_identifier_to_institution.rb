class AddProviderAndIdentifierToInstitution < ActiveRecord::Migration[5.1]
  def change
    change_table :institutions do |t|
      t.integer :provider
      t.string :identifier
      t.index :identifier
    end
    Institution.all.each do |inst|
      inst.update(provider: :saml)
    end
  end
end
