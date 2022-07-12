class AddAcceptedPrivacyPolicyToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :accepted_privacy_policy, :boolean, default: false, null: false
  end
end
