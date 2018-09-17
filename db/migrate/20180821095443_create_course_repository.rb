class CreateCourseRepository < ActiveRecord::Migration[5.1]
  def change
    create_table :course_repositories do |t|
      t.integer :course_id, null: false
      t.integer :repository_id, null: false
    end

    add_index :course_repositories, [:course_id, :repository_id], unique: true
    add_foreign_key :course_repositories, :courses
    add_foreign_key :course_repositories, :repositories

    Exercise.where(access: :private).flat_map{|e| e.series.map{|s| [e.repository, s.course]}}.uniq.each do |repository, course|
      CourseRepository.create(course_id: course.id, repository_id: repository.id) if course && repository
    end
  end
end
