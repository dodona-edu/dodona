class AddNumberToSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_column :submissions, :number, :integer
    execute "
                CREATE TRIGGER auto_increment_submission_number BEFORE INSERT ON submissions FOR EACH ROW
                SET NEW.number = (SELECT COUNT(*)+1 FROM submissions WHERE user_id = NEW.user_id AND exercise_id = NEW.exercise_id AND course_id = NEW.course_id);
            "
  end
end
