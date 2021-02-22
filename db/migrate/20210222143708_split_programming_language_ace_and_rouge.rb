class SplitProgrammingLanguageAceAndRouge < ActiveRecord::Migration[6.0]
  def change
    add_column :programming_languages, :renderer_name, :string
    ProgrammingLanguage.all.each do |pl|
      pl.update(renderer_name: pl.editor_name)
    end
    change_column_null :programming_languages, :renderer_name, false
  end
end
