class CreateAnnouncementTables < ActiveRecord::Migration[7.0]
  def change
    create_table :announcement_views do |t|
      t.integer :user_id
      t.integer :announcement_id
      t.timestamps
    end
    add_index(
      :announcement_views,
      %i[user_id announcement_id],
      unique: true,
      name: 'announcement_view_index'
    )
    create_table :announcements do |t|
      t.text :text_nl, null: false
      t.text :text_en, null: false
      t.datetime :start_delivering_at
      t.datetime :stop_delivering_at
      t.integer :user_group, null: false
      t.integer :institution_id
      t.integer :style, null: false
      t.timestamps
    end
  end
end
