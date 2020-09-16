class AddEnabledQuestionsToCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :enabled_questions, :boolean, null: false, default: true
  end
end
