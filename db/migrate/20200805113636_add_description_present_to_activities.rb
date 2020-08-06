class AddDescriptionPresentToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :description_nl_present, :boolean, default: false
    add_column :activities, :description_en_present, :boolean, default: false

    Activity.all.each do |activity|
      languages = activity.description_languages
      activity.update description_en_present: languages.include?('en'), description_nl_present: languages.include?('en')
    end
  end
end
