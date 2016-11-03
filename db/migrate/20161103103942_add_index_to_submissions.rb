class AddIndexToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_index :submissions, [:exercise_id, :user_id, :accepted, :created_at], :name => 'ex_us_ac_cr_index'
  end
end
