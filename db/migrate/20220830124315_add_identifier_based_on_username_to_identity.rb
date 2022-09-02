class AddIdentifierBasedOnUsernameToIdentity < ActiveRecord::Migration[7.0]
  def change
    add_column :identities, :identifier_based_on_username, :boolean, null: false, default: false
    Identity.joins(:provider).where(provider: {type: "Provider::Office365"}).update_all(identifier_based_on_username: true)
  end
end
