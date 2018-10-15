class AddSearchFieldToSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :search, :string

    Submission.all.each do |s|
      s.update(search: "#{s.status} #{s.user.search} #{s.exercise.name_nl} #{s.exercise.name_en} #{s.exercise.path}")
    end
  end
end
