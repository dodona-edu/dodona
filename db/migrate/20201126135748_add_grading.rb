class AddGrading < ActiveRecord::Migration[6.0]
  def change
    create_table :score_items do |t|
      t.references :evaluation_exercise, foreign_key: true, null: false
      t.decimal :maximum, precision: 5, scale: 2, null: false
      t.string :name, null: false
      t.boolean :visible, null: false, default: true
      t.text :description

      t.timestamps
    end

    create_table :scores do |t|
      t.references :score_item, foreign_key: true, null: false
      t.references :feedback, foreign_key: true, null: false
      t.decimal :score, precision: 5, scale: 2, null: false
      t.references :last_updated_by, foreign_key: { to_table: :users }, null: false, type: :integer

      t.timestamps
    end

    add_column :evaluation_exercises, :visible_score, :boolean, null: false, default: true

    # Each score item may only have one score per feedback.
    add_index :scores, [:score_item_id, :feedback_id], unique: true
  end
end
