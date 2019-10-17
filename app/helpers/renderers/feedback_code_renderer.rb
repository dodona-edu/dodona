class FeedbackCodeRenderer
  require 'json'

  def initialize(code, programming_language, messages, builder)
    @programming_language = programming_language
    @code = code
    @builder = builder
    @messages = messages
  end

  def parse
    line_formatter = Rouge::Formatters::HTML.new
    table_formatter = Rouge::Formatters::HTMLLineTable.new line_formatter, table_class: 'feedback-code-table highlighter-rouge'

    lexer = (Rouge::Lexer.find(@programming_language) || Rouge::Lexers::PlainText).new
    lexed_c = lexer.lex(@code)

    @builder.script(type: 'application/javascript') do
      @builder << 'var messages = '
      @builder << @messages.map { |o| Hash[o.each_pair.to_a] }.to_json
    end

    @builder << table_formatter.format(lexed_c)
  end
end
