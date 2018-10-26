class AddInstitutionToCourses < ActiveRecord::Migration[5.2]
  def change
    add_reference :courses, :institution, foreign_key: true
  end
end
