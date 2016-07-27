class PythiaRenderer < FeedbackTableRenderer
  def initialize(submission)
    super(submission)
    @code = submission.code
  end

  def tab_content(t)
    if t[:data][:source_annotations]
      linting(t[:data][:source_annotations], @code)
    else
      super
    end
  end

  def linting(lint_messages, code)
    @builder.div(class: 'linter') do
      @builder.ul(class: 'lint-errors') do
        lint_messages.each do |msg|
          @builder.li(class: 'lint-msg', 'data-line': msg[:line], 'data-type': msg[:type], 'data-msg': msg[:description]) do
            lint_icon(msg[:type])
            @builder.text! "#{I18n.t('submissions.show.line')} #{msg[:line]}: #{msg[:description]}"
          end
        end
      end
      source(code)
    end
  end

  def lint_icon(type)
    if type.in? %w(fatal error)
      icon_error
    elsif type.in? ['warning']
      icon_warning
    elsif type.in? %w(refactor convention)
      icon_info
    else
      icon_warning
    end
  end

  def source(code)
    @builder.div(class: 'highlighter-rouge') do
      formatter = Rouge::Formatters::HTML.new(line_numbers: true)
      lexer = Rouge::Lexers::Python.new
      @builder << formatter.format(lexer.lex(code))
    end
  end
end
