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

    only_errors = @messages.select { |message| message[:type] == :error || message[:type] == 'error' }
    compress = !only_errors.empty? && only_errors.size != @messages.size

    unless @messages.empty?
      @builder.div do
        @builder.div(class: 'feedback-table-options') do
          if compress
            @builder.span(id: 'messages-were-hidden') do
              @builder.text!(I18n.t('submissions.show.annotations.messages.were_hidden'))
            end
          end
          @builder.span(class: 'flex-spacer') do
          end
          @builder.span(class: 'diff-switch-buttons switch-buttons') do
            @builder.span do
              @builder.text!(I18n.t('submissions.show.annotations.title'))
            end
            @builder.div(class: 'btn-group btn-toggle', role: 'group', 'aria-label': I18n.t('submissions.show.annotations.title'), 'data-toggle': 'buttons') do
              @builder.button(class: "btn btn-secondary #{'active' unless compress}", id: 'show_all_annotations', title: I18n.t('submissions.show.annotations.show_all'), 'data-toggle': 'tooltip', 'data-placement': 'top') do
                @builder.i(class: 'mdi mdi-18 mdi-comment-multiple-outline') {}
              end
              if compress
                @builder.button(class: 'btn btn-secondary active', id: 'show_only_errors', title: I18n.t('submissions.show.annotations.show_errors'), 'data-toggle': 'tooltip', 'data-placement': 'top') do
                  @builder.i(class: 'mdi mdi-18 mdi-comment-alert-outline') {}
                end
              end
              @builder.button(class: 'btn btn-secondary', id: 'hide_all_annotations', title: I18n.t('submissions.show.annotations.hide_all'), 'data-toggle': 'tooltip', 'data-placement': 'top') do
                @builder.i(class: 'mdi mdi-18 mdi-comment-remove-outline') {}
              end
            end
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
      @builder << '$(() => window.dodona.codeListing.compressMessages());' if compress
    end
  end

  def html
    @builder.html_safe
  end
end
