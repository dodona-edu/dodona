class AddSearchFieldToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :search, :string

    Course.all.each do |course|
      course.update(search: "#{course.teacher || ''} #{course.name || ''}")
    end
  end
end
