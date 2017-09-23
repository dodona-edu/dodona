class CreateApiTokens < ActiveRecord::Migration[5.1]
  def change
    create_table :api_tokens do |t|
      t.belongs_to :user
      t.string :token
      t.string :description

      t.index :token

      t.timestamps
    end
  end
end
