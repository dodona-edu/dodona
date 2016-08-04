class PythiaRenderer < FeedbackTableRenderer
  def initialize(submission)
    super(submission)
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
    @builder.div(id: 'editor-result') do
      @builder.text! code
    end
    @builder << "<script>loadResultEditor('#{@programming_language}')</script>"
  end
end
