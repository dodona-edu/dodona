class AddModeAndActiveToProvider < ActiveRecord::Migration[6.0]
  def change
    add_column :providers, :mode, :integer, null: false, default: 0
    add_column :providers, :active, :boolean, default: true

    Provider.all.each do |prov|
      prov.update(mode: :prefer)
    end
  end
end
