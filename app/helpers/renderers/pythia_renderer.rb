class PythiaRenderer < FeedbackTableRenderer
  def initialize(submission, user)
    super(submission, user)
  end

  def tutor_init
      #Initialize tutor javascript
      @builder.script do
      escaped = @code.strip
          .gsub("\\n", "\\\n")
          .gsub("\n", "\\n")
          .gsub("\"", "\\\"")
          .html_safe
      javascript = """
      $(function() {
        var code = \"#{escaped}\"
        init_pythia_submission_show(code)
      });
            """
            @builder << javascript
    end
  end

  def parse
    tutor_init()
    #Tutor HTML
    @builder.div(id: "tutor") do
      @builder.div(id: "info-modal", class: "modal fade modal-info", "data-backdrop": false, tabindex: -1) do
        @builder.div(class: "modal-dialog tutor") do
          @builder.div(class: "modal-content") do
            @builder.div(class: "modal-header") do
              @builder.button(type: "button", class: "close", "data-dismiss": "modal", "aria-label": "Close") do
                @builder.span("aria-hidden": true) do
                  @builder << "&times;"
                end
              end
              @builder.h4(class: "modal-title")
            end
            @builder.div(class: "modal-body")
          end
        end
      end
    end

    super
  end

  def show_code_tab
    return true unless @submission[:groups]
    !@submission[:groups].any? { |t| t[:data][:source_annotations] }
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

  def output_message(m)
    if m[:format].in?(%w(traceback))
      @builder.div(class: 'code wrong') do
        @builder.text! m[:description]
      end
    else
      super(m)
    end
  end

  def group(g)
    @builder.div(class: "row group #{g[:accepted] ? 'correct' : 'wrong'}", "data-statements": "#{g[:data][:statements]}", "data-stdin": "#{g[:data][:stdin]}") do
      @builder.div(class: 'col-xs-12 description') do
        message(g[:description])
      end if g[:description]
      messages(g[:messages])
      g[:groups].each { |tc| testcase(tc) } if g[:groups]
    end
  end

  def testcase(tc)
    @builder.div(class: "testcase #{tc[:accepted] ? 'correct' : 'wrong'}") do
      @builder.div(class: 'col-xs-12 description') do
        @builder.div(class: 'indicator') do
          @builder.a(href: "#", class: "tutorlink") do 
            @builder.span(class: "glyphicon glyphicon-expand")
          end
          tc[:accepted] ? icon_correct : icon_wrong
        end
        message(tc[:description]) if tc[:description]
      end
      tc[:tests].each { |t| test(t) } if tc[:tests]
      messages(tc[:messages])
    end
  end

  ## custom methods

  def pythia_diff(diff)
    @builder.div(class: 'diff') do
      @builder.ul do
        diff.each do |diff_line|
          if diff_line[4]
            @builder << (diff_line[2] || '')
          else
            @builder << (diff_line[2] || '')
            @builder << (diff_line[3] || '')
          end
        end
      end
    end
  end

  def linting(lint_messages, code)
    @builder.div(class: 'linter') do
      lint_messages(lint_messages)
      source(code, lint_messages.map { |m| convert_lint_message(m) })
    end
  end

  def lint_messages(messages)
    @builder.ul(class: 'lint-errors') do
      messages.each do |msg|
        @builder.li(class: 'lint-msg') do
          lint_icon(msg[:type])
          @builder.text! "#{I18n.t('submissions.show.line')} #{msg[:line]}: "
          format_lint_message(msg[:description])
        end
      end
    end
  end

  def format_lint_message(message)
    lines = message.split("\n")
    @builder.text! lines[0]
    if lines.length > 1
      @builder.br
      @builder.div(class: 'code') do
        @builder.text! lines.drop(1).join("\n")
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
end