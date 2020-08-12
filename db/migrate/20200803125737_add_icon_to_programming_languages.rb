class AddIconToProgrammingLanguages < ActiveRecord::Migration[6.0]

  ICON_MAP = {
    'python' => 'language-python',
    'sh' => 'bash',
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
      language.update(icon: ICON_MAP[language.name])
    end
  end
end
