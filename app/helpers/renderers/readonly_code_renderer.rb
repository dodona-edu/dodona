class ReadonlyCodeRenderer
  require 'formatters/dodona_code_table_formatter'
  require 'formatters/dodona_line_annotated_formatter'

  def initialize(code, programming_language, user, messages, builder)
    @current_user = user
    @programming_language = programming_language
    @code = code
    @builder = builder
    @messages = messages
  end

  def parse
    line_formatter = Rouge::Formatters::HTML.new
    table_formatter = DodonaLineAnnotatedFormatter.new line_formatter, @messages

    lexer = (Rouge::Lexer.find(@programming_language) || Rouge::Lexers::PlainText).new
    lexed_c = lexer.lex(@code)

    @builder.style do
      # TODO: Handle dark mode
      @builder << Rouge::Themes::Github.render(scope: '.code-table')
    end

    @builder << table_formatter.format(lexed_c)
  end
end
