class FeedbackTableRenderer
  include ActionView::Helpers::JavaScriptHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  require 'builder'

  @renderers = [FeedbackTableRenderer]

  def self.inherited(cl)
    super
    @renderers << cl
  end

  class << self
    attr_reader :renderers
  end

  def initialize(submission, user)
    result = submission.safe_result(user)
    @submission = submission
    @result = result.present? ? JSON.parse(result, symbolize_names: true) : nil
    @course = submission.course
    @builder = Builder::XmlMarkup.new
    @code = submission.code
    @user = user
    @exercise = submission.exercise
    @programming_language = @exercise.programming_language&.renderer_name
  end

  def parse
    if @result.present?
      tutor_init
      @builder.div(class: 'feedback-table', 'data-exercise_id': @exercise.id) do
        if @result[:messages].present?
          @builder.div(class: 'feedback-table-messages') do
            messages(@result[:messages])
          end
        end
        tabs(@result)
        init_js
      end.html_safe
    else
      @builder.div(class: 'feedback-table', 'data-exercise_id': @exercise.id) do
        @builder.div(class: 'feedback-table-messages') do
          messages([{ description: I18n.t('submissions.show.reading_failed'), format: 'plain' }])
        end
      end.html_safe
    end
  end

  def show_code_tab
    true
  end

  def show_diff_type_switch(tab)
    tab[:groups]&.compact # Groups
                &.flat_map { |t| t[:groups] }&.compact # Testcases
                &.flat_map { |t| t[:tests] }&.compact # Tests
                &.reject { |t| t[:accepted] }
                &.any?
  end

  def show_hide_correct_switch(tab)
    tests = tab[:groups]&.compact
    tests&.any? { |t| t[:accepted] }
  end

  def tabs(submission)
    @builder.div(class: 'card-tab') do
      @builder.ul(class: 'nav nav-tabs sticky') do
        submission[:groups]&.each_with_index do |t, i|
          permission = t[:permission] || 'student'
          tooltip = case permission
                    when 'zeus'
                      I18n.t('submissions.show.tab_zeus')
                    when 'staff'
                      I18n.t('submissions.show.tab_staff')
                    else
                      ''
                    end
          @builder.li do
            id = tab_id(t, i)
            # the pythonic devil has the code tab as a generic tab
            is_code_tab = t[:data] && t[:data][:source_annotations]
            @builder.a(href: "##{id}", 'data-bs-toggle': 'tab', class: "tab-#{permission} #{'active' if i.zero?}", title: tooltip, id: is_code_tab ? 'link-to-code-tab' : nil) do
              @builder.text!("#{(t[:description] || 'Test').upcase_first} ")
              # Choose between the pythonic devil and the deep blue sea.
              if is_code_tab
                @builder.tag!('d-annotations-count-badge')
              else
                @builder.span(class: 'badge rounded-pill', id: "badge_#{id}") do
                  @builder.text! tab_count(t)
                end
              end
            end
          end
        end
        if show_code_tab
          @builder.li(class: ('active' if submission[:groups].blank?)) do
            @builder.a(href: '#code-tab', 'data-bs-toggle': 'tab', id: 'link-to-code-tab') do
              @builder.text!("#{I18n.t('submissions.show.code')} ")
              @builder.tag!('d-annotations-count-badge')
            end
          end
        end
      end
      @builder.div(class: 'tab-content') do
        @result[:groups].each_with_index { |t, i| tab(t, i) } if submission[:groups]
        if show_code_tab
          @builder.div(class: "tab-pane #{'active' if submission[:groups].blank?}", id: 'code-tab') do
            if submission[:annotations]
              @builder.div(class: 'linter') do
                source(@code, submission[:annotations])
              end
            else
              source(@code, [])
            end
          end
        end
      end
    end
  end

  def tab_count(t)
    return '' if t[:badgeCount].nil?
    return '' if t[:badgeCount].zero?

    t[:badgeCount].to_s
  end

  def tab(t, i)
    @builder.div(class: "tab-pane feedback-tab-pane #{'active' if i.zero?}", id: tab_id(t, i)) do
      tab_content(t, i)
    end
  end

  def tab_id(t, i)
    prefix = t[:description]&.parameterize
    prefix = 'test' if prefix.blank?
    "tab-#{prefix}-#{i}"
  end

  def tab_content(t, tab_i)
    @diff_type = determine_tab_diff_type(t)
    show_hide_correct = show_hide_correct_switch t
    show_diff_type = show_diff_type_switch t
    groups_correct = t[:groups]&.count { |g| g[:accepted] } || 0
    groups_total = t[:groups]&.count || 0
    expand_all = groups_correct == groups_total

    @builder.div(class: 'feedback-table-options sticky') do
      # summary of tests
      @builder.div(class: 'tab-summary') do
        if groups_total > 0
          @builder.div(class: 'tab-summary-text d-none d-md-block') do
            @builder.text! "#{groups_correct}/#{groups_total} #{I18n.t('submissions.show.correct_group').downcase}:"
          end
          @builder.div(class: 'tab-summary-icons d-none d-md-block') do
            t[:groups]&.each_with_index do |g, i|
              @builder.div(class: g[:accepted] ? 'correct' : 'wrong') do
                @builder.a(href: "#tab-#{tab_i + 1}-group-#{i + 1}", title: "##{i + 1}") do
                  @builder.i(class: "mdi mdi-12 #{g[:accepted] ? 'mdi-check' : 'mdi-close'}") {}
                end
              end
            end
          end
        end
      end

      if show_hide_correct
        @builder.span(class: 'correct-switch-buttons switch-buttons') do
          @builder.span do
            @builder << I18n.t('submissions.show.correct_tests')
          end
          @builder.div(class: 'btn-group btn-toggle') do
            @builder.button(class: "btn #{'active' if expand_all}", 'data-show': 'true', title: I18n.t('submissions.show.correct.shown'), 'data-bs-toggle': 'tooltip', 'data-bs-placement': 'top') do
              @builder.i('', class: 'mdi mdi-eye')
            end
            @builder.button(class: "btn #{'active' unless expand_all}", 'data-show': 'false', title: I18n.t('submissions.show.correct.hidden'), 'data-bs-toggle': 'tooltip', 'data-bs-placement': 'top') do
              @builder.i('', class: 'mdi mdi-eye-off')
            end
          end
        end
      end
      if show_diff_type
        @builder.span(class: 'diff-switch-buttons switch-buttons') do
          @builder.span do
            @builder << I18n.t('submissions.show.output')
          end
          @builder.div(class: 'btn-group btn-toggle') do
            @builder.button(class: "btn #{@diff_type == 'split' ? 'active' : ''}", 'data-show_class': 'show-split', title: I18n.t('submissions.show.diff.split'), 'data-bs-toggle': 'tooltip', 'data-bs-placement': 'top') do
              @builder.i(class: 'mdi mdi-arrow-split-vertical') {}
            end
            @builder.button(class: "btn #{@diff_type == 'unified' ? 'active' : ''}", 'data-show_class': 'show-unified', title: I18n.t('submissions.show.diff.unified'), 'data-bs-toggle': 'tooltip', 'data-bs-placement': 'top') do
              @builder.i(class: 'mdi mdi-arrow-split-horizontal') {}
            end
          end
        end
      end
    end
    messages(t[:messages])
    @builder.div(class: 'groups') do
      t[:groups]&.each_with_index { |g, i| group(g, i, tab_i, expand_all) }
    end
  end

  def group(g, i, tab_i, expand_all = false)
    @builder.div(class: "group card #{g[:accepted] ? 'correct' : 'wrong'} #{'collapsed' if g[:accepted] && !expand_all}", id: "tab-#{tab_i + 1}-group-#{i + 1}") do
      @builder.div(class: 'card-title card-title-colored-container') do
        @builder.a(href: "#tab-#{tab_i + 1}-group-#{i + 1}") do
          @builder.text!("##{i + 1}")
        end
        @builder.span('·', class: 'ms-2 me-2')
        @builder.span(class: 'group-status') do
          if g[:accepted]
            icon_correct
            @builder.span(I18n.t('submissions.show.correct_group'), class: 'ms-1')
          else
            icon_wrong
            @builder.span(I18n.t('submissions.show.wrong_group'), class: 'ms-1')
          end
        end

        @builder.div(class: 'flex-spacer') {}

        # Add a link to the debugger if there is data
        if g[:data] && (g[:data][:statements] || g[:data][:stdin])
          @builder.a(class: 'btn btn-text tutorlink',
                     title: 'Start debugger',
                     'data-statements': (g[:data][:statements]).to_s,
                     'data-stdin': (g[:data][:stdin]).to_s) do
            # this is the bug-play-outline icon from https://pictogrammers.com/library/mdi/icon/bug-play-outline/
            @builder.i(class: 'mdi me-1 custom-material-icons') do
              @builder << '<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 0 24 24" width="24px" fill="currentColor"><path d="M19 7H16.19C15.74 6.2 15.12 5.5 14.37 5L16 3.41L14.59 2L12.42 4.17C11.96 4.06 11.5 4 11 4S10.05 4.06 9.59 4.17L7.41 2L6 3.41L7.62 5C6.87 5.5 6.26 6.21 5.81 7H3V9H5.09C5.03 9.33 5 9.66 5 10V11H3V13H5V14C5 14.34 5.03 14.67 5.09 15H3V17H5.81C7.26 19.5 10.28 20.61 13 19.65V19C13 18.43 13.09 17.86 13.25 17.31C12.59 17.76 11.8 18 11 18C8.79 18 7 16.21 7 14V10C7 7.79 8.79 6 11 6S15 7.79 15 10V14C15 14.19 15 14.39 14.95 14.58C15.54 14.04 16.24 13.62 17 13.35V13H19V11H17V10C17 9.66 16.97 9.33 16.91 9H19V7M13 9V11H9V9H13M13 13V15H9V13H13M17 16V22L22 19L17 16Z" /></svg>'
            end
            @builder.text!(I18n.t('submissions.show.debug'))
          end
        end

        # Expand/collapse button
        @builder.a(class: 'btn btn-icon btn-collapse') do
          @builder.i(class: 'mdi mdi-chevron-down') {}
        end
      end

      @builder.div(class: 'card-supporting-text') do
        if g[:description]
          @builder.div(class: 'row') do
            @builder.div(class: 'col-12 description') do
              message(g[:description])
            end
          end
        end
        messages(g[:messages])
        g[:groups]&.each { |tc| testcase(tc) }
      end
    end
  end

  def testcase(tc)
    @builder.div(class: "testcase #{tc[:accepted] ? 'correct' : 'wrong'}") do
      testcase_content(tc)
    end
  end

  def testcase_content(tc)
    @builder.div(class: 'description') do
      @builder.div(class: 'indicator') do
        tc[:accepted] ? icon_correct : icon_wrong
      end
      message(tc[:description]) if tc[:description]
    end
    tc[:tests]&.each { |t| test(t) }

    @builder.div(class: 'messages') { messages(tc[:messages]) } if tc[:messages]
  end

  def test(t)
    @builder.div(class: 'test') do
      if t[:description]
        @builder.div(class: 'description') do
          message(t[:description])
        end
      elsif (channel = t[:data]&.fetch(:channel, nil) || t[:channel])
        @builder.div(class: 'description') do
          @builder.span(class: "badge bg-#{t[:accepted] ? 'success' : 'danger'}") do
            @builder.text! channel
          end
        end
      end
      if t[:accepted]
        test_accepted(t)
      else
        test_failed(t)
      end
      messages(t[:messages])
    end
  end

  def messages(msgs)
    return if msgs.blank?

    @builder.div(class: 'messages') do
      msgs.each do |msg|
        permission = msg.is_a?(Hash) && msg.key?(:permission) ? msg[:permission] : 'student'
        tooltip = case permission
                  when 'zeus'
                    I18n.t('submissions.show.message_zeus')
                  when 'staff'
                    I18n.t('submissions.show.message_staff')
                  else
                    ''
                  end
        @builder.div(class: "message message-#{permission}", title: tooltip) do
          message(msg)
        end
      end
    end
  end

  def differ(t)
    if t[:format] == 'csv' && CsvDiffer.limited_columns?(t[:generated]) && CsvDiffer.limited_columns?(t[:expected])
      CsvDiffer
    else
      TextDiffer
    end
  end

  def test_accepted(t)
    @builder.div(class: 'test-accepted') do
      differ(t).render_accepted(@builder, t[:generated])
    end
  end

  def test_failed(t)
    @builder.div(class: 'test-failed') do
      diff(t)
    end
  end

  def diff(t)
    differ = differ(t).new(t[:generated], t[:expected])
    @builder.div(class: "diffs show-#{@diff_type}") do
      @builder << differ.split
      @builder << differ.unified
    end
  end

  def message(m)
    return if m.nil?

    m = { format: 'plain', description: m } if m.is_a? String
    output_message(m)
  end

  def output_message(m)
    if m[:format].in?(%w[plain text])
      @builder.text! m[:description]
    elsif m[:format].in?(%w[html])
      @builder << safe(m[:description])
    elsif m[:format].in?(%w[markdown md])
      # `markdown` is always safe
      @builder << markdown(m[:description])
    elsif m[:format].in?(%w[callout])
      @builder.div(class: 'callout callout-info') do
        # `markdown` is always safe
        @builder << markdown(m[:description])
      end
    elsif m[:format].in?(%w[callout-info callout-warning callout-danger])
      @builder.div(class: "callout #{m[:format]}") do
        # `markdown` is always safe
        @builder << markdown(m[:description])
      end
    elsif m[:format].in?(%w[code])
      @builder.span(class: 'code') do
        @builder.text! m[:description]
      end
    else
      @builder.span(class: "code highlighter-rouge #{m[:format]}") do
        formatter = Rouge::Formatters::HTML.new(wrap: false)
        lexer = (Rouge::Lexer.find(m[:format].downcase) || Rouge::Lexers::PlainText).new
        @builder << formatter.format(lexer.lex(m[:description]))
      end
    end
  end

  def init_js
    @builder.script do
      token = @exercise.access_private? ? "'#{@exercise.access_token}'" : 'undefined'
      @builder << "dodona.initSubmissionShow('feedback-table', '#{activity_path(nil, @exercise)}', #{token});"
    end
  end

  def source(_, messages)
    @builder.div(class: 'code-table', 'data-submission-id': @submission.id) do
      @builder << FeedbackCodeRenderer.new(@code, @programming_language)
                                      .add_messages(@submission, messages, @user)
                                      .add_code
                                      .html
    end
  end

  def determine_tab_diff_type(tab)
    tab[:groups]&.each do |group|
      group[:groups]&.each do |testcase|
        testcase[:tests]&.each do |test|
          return 'unified' if determine_diff_type(test) == 'unified'
        end
      end
    end
    'split'
  end

  def determine_diff_type(test)
    return 'split' if test[:format] == 'csv'

    output = "#{test[:expected].to_s || ''}\n#{test[:generated].to_s || ''}"
    if output.split("\n", -1).map(&:length).max < 55
      'split'
    else
      'unified'
    end
  end

  def icon_testcase
    @builder.span('► ', class: 'testcase-icon')
  end

  def icon_correct
    @builder.i('', class: 'mdi mdi-check mdi-18')
  end

  def icon_wrong
    @builder.i('', class: 'mdi-close mdi mdi-18')
  end

  def icon_warning
    @builder.i('', class: 'mdi mdi-alert mdi-18')
  end

  def icon_error
    @builder.i('', class: 'mdi mdi-alert-circle mdi-18')
  end

  def icon_info
    @builder.i('', class: 'mdi mdi-alert-circle mdi-18')
  end

  def safe(html)
    if @exercise.allow_unsafe?
      html
    else
      sanitize html
    end
  end

  def tutor_init
    # Initialize tutor javascript
    @builder.script do
      escaped = escape_javascript(@code.strip)
      @builder << 'dodona.ready.then(function() {'
      @builder << "dodona.initTutor(\"#{escaped}\");});"
    end
  end
end
