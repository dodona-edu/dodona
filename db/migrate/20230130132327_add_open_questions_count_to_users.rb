class AddOpenQuestionsCountToUsers < ActiveRecord::Migration[7.0]
  def self.up
    add_column :users, :open_questions_count, :integer, null: false, default: 0

    # User.find_each do |u|
    #   u.update(open_questions_count: u.questions.where.not(question_state: :answered).count)
    # end
  end

  def self.down
    remove_column :users, :open_questions_count
  end
end
