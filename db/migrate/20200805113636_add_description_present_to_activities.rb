class AddDescriptionPresentToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :description_nl_present, :boolean, default: false
    add_column :activities, :description_en_present, :boolean, default: false

    Activities.all.each do |activity|
      languages = activity.description_languages
      if languages.include? 'en'
        activity.update description_en_present: true
      end
      if languages.include? 'nl'
        activity.update description_nl_present: true
      end
    end
  end
end
