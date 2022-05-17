class CreateAnnouncementTables < ActiveRecord::Migration[7.0]
  def change
    create_table :announcements do |t|
      t.text :text_nl, null: false
      t.text :text_en, null: false
      t.datetime :start_delivering_at
      t.datetime :stop_delivering_at
      t.integer :user_group, null: false
      t.references :institution, foreign_key: true, null: true, type: :bigint
      t.integer :style, null: false
      t.timestamps
    end
    create_table :announcement_views do |t|
      t.references :announcement, foreign_key: true, null: false, type: :bigint
      t.references :user, foreign_key: true, null: false, type: :integer
      t.timestamps
    end
    add_index(
      :announcement_views,
      %i[user_id announcement_id],
      unique: true
    )
  end
end
