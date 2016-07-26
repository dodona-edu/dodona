class PythiaRenderer < FeedbackTableRenderer
  def initialize(submission)
    super(submission)
    @code = submission.code
  end

  def tab_content(t)
    if t[:data][:lint_messages]
      linting(t[:data][:lint_messages], @code)
    else
      super
    end
  end

  def linting(lint_messages, code)
    @builder.div do
      @builder.ul do
        lint_messages.each do |msg|
          @builder.li(msg.to_s)
        end
      end
      formatter = Rouge::Formatters::HTML.new
      lexer = Rouge::Lexers::Python.new
      @builder << formatter.format(lexer.lex(code))
    end
  end
end
