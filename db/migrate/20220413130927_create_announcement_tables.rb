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
      t.text :title
      t.text :body
      t.datetime :start_delivering_at
      t.datetime :stop_delivering_at
      t.int :user_group
      t.int :institution_id
      t.int :style
      t.timestamps
    end
  end
end
