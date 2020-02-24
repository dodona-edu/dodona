class CreateAnnotations < ActiveRecord::Migration[6.0]
  def change
    create_table :annotations do |t|
      t.integer :line_nr
      t.references :submission, foreign_key: true, type: :integer
      t.references :user, foreign_key: true, type: :integer
      t.text :annotation_text

      t.timestamps
    end
  end
end
