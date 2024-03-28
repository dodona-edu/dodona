class RemoveUniqueKeyOnSavedAnnotationTitle < ActiveRecord::Migration[7.0]
  def change
    remove_index :saved_annotations,  name: "index_saved_annotations_title_uid_eid_cid"
  end
end
