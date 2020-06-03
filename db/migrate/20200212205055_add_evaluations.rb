class AddEvaluations < ActiveRecord::Migration[6.0]
  def change
    create_table :evaluations do |t|
      t.references :series, foreign_key: true, type: :integer, unique: true
      t.boolean :released, default: false, null: false
      t.datetime :deadline, null: false
      t.timestamps
    end

    create_table :evaluation_exercises do |t|
      t.references :evaluation, foreign_key: true
      t.references :exercise, foreign_key: { to_table: :activities }, type: :integer
      t.index [:exercise_id, :evaluation_id], unique: true
      t.timestamps
    end

    create_table :evaluation_users do |t|
      t.references :evaluation, foreign_key: true
      t.references :user, foreign_key: true, type: :integer
      t.index [:user_id, :evaluation_id], unique: true
      t.timestamps
    end

    create_table :feedbacks do |t|
      t.references :submission, foreign_key: true, type: :integer
      t.references :evaluation, foreign_key: true
      t.references :evaluation_user, foreign_key: true
      t.references :evaluation_exercise, foreign_key: true
      t.boolean :completed, default: false, null: false
      t.timestamps
    end

    add_reference :annotations, :evaluation, foreign_key: true
  end
end
