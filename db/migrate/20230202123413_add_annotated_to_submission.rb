class AddAnnotatedToSubmission < ActiveRecord::Migration[7.0]
  def change
    add_column :submissions, :annotated, :boolean, default: false, null: false

    Submission.where(id: Annotation.released.select(:submission_id).distinct).update_all(annotated: true)
  end
end
