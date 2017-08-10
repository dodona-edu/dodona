class ChangeCourseOpenToAccessEnum < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      change_table :courses do |t|
        dir.up do
          t.remove :open
          t.column :access, :integer, default: Course.accesses['open']
        end
        dir.down do
          t.remove :access
          t.column :open, :boolean
        end
      end
    end
  end
end
