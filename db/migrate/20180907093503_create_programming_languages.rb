class CreateProgrammingLanguages < ActiveRecord::Migration[5.2]
  def change
    create_table :programming_languages do |t|
      t.string :name, null: false
      t.string :markdown_name, null: false
      t.string :editor_name, null: false
      t.string :extension, null: false

      t.timestamps
    end
    add_index :programming_languages, :name, unique: true

    def file_extension(programming_language)
      return 'py' if programming_language == 'python'
      return 'js' if programming_language == 'JavaScript'
      return 'hs' if programming_language == 'haskell'
      return 'sh' if programming_language == 'bash'
      return 'sh' if programming_language == 'shell'
      return 'sh' if programming_language == 'sh'
      'txt'
    end

    Exercise.all.map{|e| e.programming_language}.uniq.compact.each do |name|
      ProgrammingLanguage.create(name: name, markdown_name: name, editor_name: name, extension: file_extension(name))
    end

    add_column :exercises, :programming_language_id, :bigint

    Exercise.find_each do |e|
      e.update_columns(programming_language_id: ProgrammingLanguage.find_by(name: e.programming_language)&.id)
    end

    remove_column :exercises, :programming_language
    add_foreign_key :exercises, :programming_languages
  end
end
