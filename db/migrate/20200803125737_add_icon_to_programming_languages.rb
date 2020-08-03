class AddIconToProgrammingLanguages < ActiveRecord::Migration[6.0]

  @@icon_map = {
    'python' => 'language-python',
    'sh' => 'mdi-bash',
    'javascript' => 'language-javascript',
    'bash' => 'bash',
    'java' => 'language-java',
    'prolog' => 'owl',
    'haskell' => 'language-haskell',
    'R' => 'language-r',
    'csharp' => 'language-csharp',
    'text' => nil
  }
  def change
    add_column :programming_languages, :icon, :string

    ProgrammingLanguage.all.each do |language|
      language.update(icon: @@icon_map[language.name])
    end
  end
end
