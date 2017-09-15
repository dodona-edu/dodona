class ChangeCourseRegistrationAndVisibility < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      change_table :courses do |t|
        dir.up do
          t.remove :open
          t.column :visibility, :integer, default: Course.visibilities['visible']
          t.column :registration, :integer, default: Course.registrations['open']
        end
        dir.down do
          t.remove :visibility
          t.remove :registration
          t.column :open, :boolean
        end
      end
    end
  end
end
