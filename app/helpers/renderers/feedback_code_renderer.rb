class FeedbackCodeRenderer
  require 'json'

  def initialize(code, programming_language, messages, builder)
    @code = code
    @programming_language = programming_language
    @messages = messages
    @builder = builder
  end

  def parse
    line_formatter = Rouge::Formatters::HTML.new
    table_formatter = Rouge::Formatters::HTMLLineTable.new line_formatter, table_class: 'code-listing highlighter-rouge'

    lexer = (Rouge::Lexer.find(@programming_language) || Rouge::Lexers::PlainText).new
    lexed_c = lexer.lex(@code)

    @builder << table_formatter.format(lexed_c)

    @builder.script(type: 'application/javascript') do
      @builder << 'const messages = '
      @builder << @messages.map { |o| Hash[o.each_pair.to_a] }.to_json
      @builder << ';'

      @builder << 'var codeListing = new window.dodona.codeListingClass();'
      @builder << 'window.dodona.codeListing = codeListing;'
      @builder << 'codeListing.addAnnotations(messages);'
    end
  end
end
