class RemoveMarkdownNameFromProgrammingLanguage < ActiveRecord::Migration[5.2]
  def change
    remove_column :programming_languages, :markdown_name
  end
end
