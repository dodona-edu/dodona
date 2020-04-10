class AddReviews < ActiveRecord::Migration[6.0]
  def up
    create_table :review_sessions do |t|
      t.references :series, foreign_key: true, type: :integer
      t.boolean :released, default: false, null: false
      t.datetime :deadline, null: false
      t.timestamps
    end

    create_table :review_exercises do |t|
      t.references :review_session, foreign_key: true, type: :bigint
      t.references :exercise, foreign_key: true, type: :integer
      t.timestamps
    end

    create_table :reviews do |t|
      t.references :submission, foreign_key: true, type: :integer
      t.references :review_session, foreign_key: true, type: :bigint
      t.references :user, foreign_key: true, type: :integer
      t.references :review_exercise, { foreign_key: true, type: :bigint}
      t.boolean :completed, default: false, null: false
      t.timestamps
    end

    add_reference :annotations, :review_session, type: :bigint, foreign_key: true
  end

  def down
    remove_reference :annotations, :review_session

    drop_table :reviews
    drop_table :review_exercises
    drop_table :review_sessions
  end
end
