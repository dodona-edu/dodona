class AddCourseToSubmissions < ActiveRecord::Migration[5.0]
  def self.up
    add_reference :submissions, :course, foreign_key: true

    execute "UPDATE submissions, (SELECT submissions.id, series.course_id AS cid FROM submissions LEFT JOIN series_memberships ON submissions.exercise_id = series_memberships.exercise_id LEFT JOIN series ON series_memberships.series_id = series.id) AS t1,(SELECT submissions.id, course_memberships.course_id AS cid FROM submissions LEFT JOIN course_memberships ON submissions.user_id = course_memberships.user_id) as t2 SET submissions.course_id = t1.cid WHERE submissions.id = t1.id AND submissions.id = t2.id AND t1.cid = t2.cid"
  end

  def self.down
    remove_reference :submissions, :course, foreign_key: true
  end
end
