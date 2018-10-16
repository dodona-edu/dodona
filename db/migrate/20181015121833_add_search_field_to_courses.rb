class AddSearchFieldToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :search, :string, :limit => 4096

    Course.find_each do |course|
      course.set_search
      course.save
    end
  end
end
