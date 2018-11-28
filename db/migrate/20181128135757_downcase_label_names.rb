class DowncaseLabelNames < ActiveRecord::Migration[5.2]
  def change
    Label.find_each do |l|
      l.update(name: l.name.downcase)
    end
  end
end
