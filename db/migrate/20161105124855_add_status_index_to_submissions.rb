class AddStatusIndexToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_index :submissions, [:exercise_id, :user_id, :status, :created_at], :name => 'ex_us_st_cr_index'
  end
end
