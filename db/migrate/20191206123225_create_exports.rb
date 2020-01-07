class CreateExports < ActiveRecord::Migration[6.0]
  def change
    create_table :exports do |t|
      t.references :user, foreign_key: true, type: :integer
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
