# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerSubmissionsInsert < ActiveRecord::Migration[7.0]
  def up
    create_trigger("submissions_before_insert_row_tr", :compatibility => 1).
        on("submissions").
        before(:insert) do
      "SET NEW.number = (SELECT COUNT(*)+1 FROM submissions WHERE user_id = NEW.user_id AND exercise_id = NEW.exercise_id AND (course_id = NEW.course_id OR (course_id IS NULL and NEW.course_id IS NULL)));"
    end
  end

  def down
    drop_trigger("submissions_before_insert_row_tr", "submissions")
  end
end
