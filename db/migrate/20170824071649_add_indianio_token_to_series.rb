class AddIndianioTokenToSeries < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        add_column    :series, :indianio_token, :string
        add_index     :series, :indianio_token
        rename_column :series, :token, :access_token
      end
      dir.down do
        remove_column :series, :indianio_token
        remove_index  :series, :indianio_token
        rename_column :series, :access_token, :token
      end
    end
  end
end
