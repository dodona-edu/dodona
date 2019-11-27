class RemovePosts < ActiveRecord::Migration[6.0]
  def change
    drop_table :posts
    drop_table :action_text_rich_texts
    ActiveStorage::Attachment.find_each(&:purge)
    drop_table :active_storage_attachments
    drop_table :active_storage_blobs
  end
end
