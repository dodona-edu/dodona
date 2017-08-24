class AddScoreTokenToSeries < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        add_column    :series, :score_token, :string
        add_index     :series, :score_token
        rename_column :series, :token, :access_token
      end
      dir.down do
        remove_column :series, :score_token
        remove_index  :series, :score_token
        rename_column :series, :access_token, :token
      end
    end
  end
end
