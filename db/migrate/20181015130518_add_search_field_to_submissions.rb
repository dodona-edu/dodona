class AddSearchFieldToSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :search, :string, :limit => 4096

    Submission.all.each do |s|
      s.set_search
      s.save
    end
  end
end
