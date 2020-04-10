class AddReviews < ActiveRecord::Migration[6.0]
  def change
    create_table :review_sessions do |t|
      t.references :series, foreign_key: true, type: :integer
      t.boolean :released, default: false, null: false
      t.datetime :deadline, null: false
      t.timestamps
    end

    create_table :review_activities do |t|
      t.references :review_session, foreign_key: true
      t.references :activity, foreign_key: true, type: :integer
      t.timestamps
    end

    create_table :reviews do |t|
      t.references :submission, foreign_key: true, type: :integer
      t.references :review_session, foreign_key: true
      t.references :user, foreign_key: true, type: :integer
      t.references :review_activity, foreign_key: true
      t.boolean :completed, default: false, null: false
      t.timestamps
    end

    add_reference :annotations, :review_session, foreign_key: true
  end
end
