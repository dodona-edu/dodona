class AddDescriptionPresentToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :description_nl_present, :boolean, default: false
    add_column :activities, :description_en_present, :boolean, default: false
  end
end
