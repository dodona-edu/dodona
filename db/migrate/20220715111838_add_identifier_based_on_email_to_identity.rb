class AddIdentifierBasedOnEmailToIdentity < ActiveRecord::Migration[7.0]
  def change
    add_column :identities, :identifier_based_on_email, :boolean, default: false, null: false
  end
end
