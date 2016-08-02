class PythiaRenderer < FeedbackTableRenderer
  def initialize(submission, user)
    super(submission, user)
    @code = submission.code
    @programming_language = submission.exercise.programming_language
  end

  def tab_content(t)
    if t[:data][:source_annotations]
      linting(t[:data][:source_annotations], @code)
    else
      super
    end
  end

  def diff(t)
    if t[:data][:diff]
      pythia_diff(t[:data][:diff])
    else
      super
    end
  end

  def test_accepted(t)
    if t[:data][:diff]
      @builder.div(class: 'test-accepted') do
        diff(t)
      end
    else
      super
    end
  end

  ## custom methods

  def pythia_diff(diff)
    @builder.div(class: 'diff') do
      @builder.ul do
        diff.each do |diff_line|
          if diff_line[4]
            @builder << diff_line[2]
          else
            @builder << diff_line[2]
            @builder << diff_line[3]
          end
        end
      end
    end
  end

  def linting(lint_messages, code)
    @builder.div(class: 'linter') do
      lint_messages(lint_messages)
      source(code, lint_messages)
    end
  end

  def lint_messages(messages)
    @builder.ul(class: 'lint-errors') do
      messages.each do |msg|
        @builder.li(class: 'lint-msg') do
          lint_icon(msg[:type])
          @builder.text! "#{I18n.t('submissions.show.line')} #{msg[:line]}: #{msg[:description]}"
        end
      end
    end
  end

  def lint_icon(type)
    send('icon_' + convert_lint_type(type))
  end

  def convert_lint_type(type)
    if type.in? %w(fatal error)
      'error'
    elsif type.in? ['warning']
      'warning'
    elsif type.in? %w(refactor convention)
      'error'
    else
      'warning'
    end
  end

  def convert_lint_message(message)
    {
      row: message[:line] - 1,
      type: convert_lint_type(message[:type]),
      text: message[:description]
    }
  end

  def source(code, messages)
    @builder.div(id: 'editor-result') do
      @builder.text! code
    end
    annotations = messages.map { |msg| convert_lint_message(msg) }
    @builder << "<script>$(function () {loadResultEditor('#{@programming_language}', #{annotations.to_json});});</script>"
  end
end
