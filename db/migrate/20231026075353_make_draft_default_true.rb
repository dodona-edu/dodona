class MakeDraftDefaultTrue < ActiveRecord::Migration[7.1]
  def change
    change_column_default :activities, :draft, from: false, to: true
  end
end
