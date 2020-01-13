class AddIconClassToProgrammingLanguage < ActiveRecord::Migration[6.0]
  def change
    add_column :programming_languages, :icon_class, :string
    reversible do |dir|
      dir.up do
        # Programming language icons in the Material Design Icons as of today.
        existing_icons = %w[c cpp csharp css3 fortran go haskell html5 java
        javascript lua php python r ruby-on-rails swift typescript]
        ProgrammingLanguage.all.each do |lang|
          if existing_icons.include? lang.name
            lang.update(icon_class: "mdi-language-#{lang.name}")
          end
        end
      end
      dir.down {}
    end
  end
end
