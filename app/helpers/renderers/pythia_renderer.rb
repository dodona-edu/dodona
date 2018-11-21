class PythiaRenderer < FeedbackTableRenderer
  include ActionView::Helpers::JavaScriptHelper

  def initialize(submission, user)
    super(submission, user)
  end

  def parse
    tutor_init
    super
  end

  def show_code_tab
    return true unless @submission[:groups]
    @submission[:groups].none? {|t| t[:data][:source_annotations]}
  end

  def show_diff_type_switch(tab)
    tab[:groups]&.compact # Groups
        &.flat_map {|t| t[:groups]}&.compact # Testcases
        &.flat_map {|t| t[:tests]}&.compact # Tests
        &.reject {|t| t[:accepted]}
        &.select {|t| t[:data][:diff].nil?}
        &.any?
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
    if m[:format].in?(%w[traceback])
      @builder.div(class: 'code wrong') do
        @builder.text! m[:description]
      end
    else
      super(m)
    end
  end

  def group(g)
    if g.key?(:data)
      @builder.div(class: "row group #{g[:accepted] ? 'correct' : 'wrong'}",
                   "data-statements": (g[:data][:statements]).to_s,
                   "data-stdin": (g[:data][:stdin]).to_s) do
        @builder.div(class: 'tutor-strip tutorlink', title: 'Start debugger') do
          @builder.div(class: 'tutor-strip-icon') do
            @builder.i('launch', class: 'material-icons md-18')
          end
        end
        if g[:description]
          @builder.div(class: 'col-xs-12 description') do
            message(g[:description])
          end
        end
        messages(g[:messages])
        g[:groups]&.each {|tc| testcase(tc)}
      end
    else
      super(g)
    end
  end

  def testcase(tc)
    return super(tc) unless tc[:data] && tc[:data][:files]
    jsonfiles = tc[:data][:files].to_json
    @builder.div(class: "testcase #{tc[:accepted] ? 'correct' : 'wrong'} contains-file", "data-files": jsonfiles) do
      testcase_content(tc)
    end
  end

  ## custom methods

  def tutor_init
    # Initialize tutor javascript
    @builder.script do
      escaped = escape_javascript(@code.strip)
      @builder << '$(function() {'
      @builder << "$('#tutor').appendTo('body');"
      @builder << "var code = \"#{escaped}\";"
      @builder << 'dodona.initPythiaSubmissionShow(code);});'
    end

    # Tutor HTML
    @builder.div(id: 'tutor', class: 'tutormodal') do
      @builder.div(id: 'info-modal', class: 'modal fade modal-info', "data-backdrop": true, tabindex: -1) do
        @builder.div(class: 'modal-dialog tutor') do
          @builder.div(class: 'modal-content') do
            @builder.div(class: 'modal-header') do
              @builder.div(class: 'icons') do
                @builder.button(id: 'fullscreen-button', type: 'button', class: 'btn btn-link btn-xs') do
                  @builder.i('fullscreen', class: 'material-icons md-18')
                end
                @builder.button(type: 'button', class: 'btn btn-link btn-xs', "data-dismiss": 'modal') do
                  @builder.i('close', class: 'material-icons md-18')
                end
              end
              @builder.h4(class: 'modal-title')
            end
            @builder.div(class: 'modal-body') {}
          end
        end
      end
    end
  end

  def pythia_diff(diff)
    @builder.div(class: 'diff') do
      @builder.ul do
        diff.each do |diff_line|
          @builder << (diff_line[2] || '')
          @builder << (diff_line[3] || '') unless diff_line[4]
        end
      end
    end
  end

  def linting(lint_messages, code)
    @builder.div(class: 'linter') do
      lint_messages(lint_messages)
      source(code, lint_messages.map {|m| convert_lint_message(m)})
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
    return unless lines.length > 1
    @builder.br
    @builder.div(class: 'code') do
      @builder.text! lines.drop(1).join("\n")
    end
  end

  def lint_icon(type)
    send('icon_' + convert_lint_type(type))
  end

  def convert_lint_type(type)
    if type.in? %w[fatal error]
      'error'
    elsif type.in? ['warning']
      'warning'
    elsif type.in? %w[refactor convention]
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
