class FeedbackCodeRenderer
  require 'json'

  def initialize(code, programming_language, builder = nil)
    @code = code
    @programming_language = programming_language
    @builder = builder || Builder::XmlMarkup.new
  end

  def parse
    line_formatter = Rouge::Formatters::HTML.new
    table_formatter = Rouge::Formatters::HTMLLineTable.new line_formatter, table_class: 'code-listing highlighter-rouge'

    lexer = (Rouge::Lexer.find(@programming_language) || Rouge::Lexers::PlainText).new
    lexed_c = lexer.lex(@code)

    only_errors = @messages.select { |message| message[:type] == :error }

    if !only_errors.empty? && only_errors.size != @messages.size
      @builder.div(class: 'code-listing-options') do
        @builder.span(class: 'flex-spacer') {}
        @builder.div(class: 'btn-group btn-toggle') do
          @builder.button(class: 'btn btn-secondary', id: 'show_extra_annotations') do
            @builder.text!(I18n.t('submissions.show.annotations.show_all'))
          end
          @builder.button(class: 'btn btn-secondary active', id: 'hide_extra_annotations') do
            @builder.text!(I18n.t('submissions.show.annotations.hide_all'))
          end
        end
      end
    end

    @builder << table_formatter.format(lexed_c)
    self
  end

  def add_messages(messages)
    @builder.script(type: 'application/javascript') do
      @builder << 'window.dodona.codeListing = new window.dodona.codeListingClass();'
      @builder << '$(() => window.dodona.codeListing.addAnnotations(' + @messages.map { |o| Hash[o.each_pair.to_a] }.to_json + '));'
    end
  end

  def html
    @builder.html_safe
  end
end
