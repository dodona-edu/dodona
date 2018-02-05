class RenameApiTokenTokenToTokenDigest < ActiveRecord::Migration[5.1]
  def change
    rename_column :api_tokens, :token, :token_digest
  end
end
