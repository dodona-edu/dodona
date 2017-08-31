class FeedbackTableRenderer
  include ApplicationHelper

  require 'builder'

  @renderers = [FeedbackTableRenderer]
  def self.inherited(cl)
    @renderers << cl
  end

  class << self
    attr_reader :renderers
  end

  def initialize(submission, user)
    @submission = JSON.parse(submission.result, symbolize_names: true)
    @current_user = user
    @builder = Builder::XmlMarkup.new
    @code = submission.code
    @exercise_id = submission.exercise_id
    @programming_language = submission.exercise.programming_language
  end

  def parse
    @builder.div(class: 'feedback-table', "data-exercise_id": @exercise_id) do
      @builder.div(class: 'row feedback-table-messages') do
        messages(@submission[:messages])
      end
      tabs(@submission)
      init_js
    end.html_safe
  end

  def show_code_tab
    true
  end

  def tabs(submission)
    @builder.div(class: 'card card-nav') do
      @builder.div(class: 'card-title card-title-colored') do
        @builder.ul(class: 'nav nav-tabs') do
          submission[:groups]&.each_with_index do |t, i|
            @builder.li(class: ('active' if i.zero?)) do
              @builder.a(href: "##{(t[:description] || 'test').parameterize}-#{i}", 'data-toggle': 'tab') do
                @builder.text!((t[:description] || 'Test').upcase_first + ' ')
                @builder.span(class: 'badge') do
                  @builder << tab_count(t)
                end
              end
            end
          end
          if show_code_tab
            @builder.li(class: ('active' unless submission[:groups])) do
              @builder.a(I18n.t('submissions.show.code'), href: '#code-tab', 'data-toggle': 'tab')
            end
          end
        end
      end
      @builder.div(class: 'card-supporting-text') do
        @builder.div(class: 'tab-content') do
          @submission[:groups].each_with_index { |t, i| tab(t, i) } if submission[:groups]
          if show_code_tab
            @builder.div(class: "tab-pane #{'active' unless submission[:groups]}", id: 'code-tab') do
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
    return '' if t[:badgeCount] == '0'
    t[:badgeCount].to_s
  end

  def tab(t, i)
    @builder.div(class: "tab-pane #{'active' if i.zero?}", id: "#{(t[:description] || 'test').parameterize}-#{i}") do
      tab_content(t)
    end
  end

  def tab_content(t)
    @diff_type = determine_tab_diff_type(t)
    messages(t[:messages])
    @builder.div(class: 'groups') do
      t[:groups]&.each { |g| group(g) }
    end
  end

  def group(g)
    @builder.div(class: "row group #{g[:accepted] ? 'correct' : 'wrong'}") do
      if g[:description]
        @builder.div(class: 'col-xs-12 description') do
          message(g[:description])
        end
      end
      messages(g[:messages])
      g[:groups]&.each { |tc| testcase(tc) }
    end
  end

  def testcase_icons(tc); end

  def testcase(tc)
    @builder.div(class: "testcase #{tc[:accepted] ? 'correct' : 'wrong'}") do
      testcase_content(tc)
    end
  end

  def testcase_content(tc)
    @builder.div(class: 'col-xs-12 description') do
      @builder.div(class: 'indicator') do
        testcase_icons(tc)
        tc[:accepted] ? icon_correct : icon_wrong
      end
      message(tc[:description]) if tc[:description]
    end
    tc[:tests]&.each { |t| test(t) }
    messages(tc[:messages])
  end

  def test(t)
    @builder.div(class: 'col-xs-12 test') do
      if t[:description]
        @builder.div(class: 'description') do
          message(t[:description])
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
    return if msgs.nil?
    @builder.div(class: 'col-xs-12 messages') do
      msgs.each do |msg|
        @builder.div(class: 'message') do
          message(msg)
        end
      end
    end
  end

  def test_accepted(t)
    @builder.div(class: 'test-accepted') do
      # icon_correct
      @builder.span(t[:generated], class: 'output')
    end
  end

  def test_failed(t)
    @builder.div(class: 'test-accepted') do
      diff(t)
    end
  end

  def diff(t)
    diff_heuristical(t)
  end

  def diff_heuristical(t)
    if @diff_type == 'split'
      diff_split(t)
    else
      diff_unified(t)
    end
  end

  def diff_unified(t)
    @builder << Diffy::Diff.new(t[:generated], t[:expected]).to_s(:html)
  end

  def diff_split(t)
    d = Diffy::SplitDiff.new(t[:generated], t[:expected], format: :html)
    @builder.div(class: 'row') do
      @builder.div(class: 'col-sm-6 col-xs-12', title: I18n.t('submissions.show.generated')) do
        @builder << d.left
      end
      @builder.div(class: 'col-sm-6 col-xs-12', title: I18n.t('submissions.show.expected')) do
        @builder << d.right
      end
    end
  end

  def message(m)
    return if m.nil?
    m = { format: 'plain', description: m } if m.is_a? String
    if m[:permission]
      return if m[:permission] == 'staff' && !@current_user.admin?
      return if m[:permission] == 'zeus' && !@current_user.zeus?
    end
    output_message(m)
  end

  def output_message(m)
    if m[:format].in?(%w[plain text])
      @builder.text! m[:description]
    elsif m[:format].in?(%w[html])
      @builder << m[:description]
    elsif m[:format].in?(%w[markdown md])
      @builder << markdown(m[:description])
    elsif m[:format].in?(%w[code])
      @builder.span(class: 'code') do
        @builder.text! m[:description]
      end
    else
      @builder.span(class: 'code highlighter-rouge') do
        formatter = Rouge::Formatters::HTML.new(wrap: false)
        lexer = (Rouge::Lexer.find(m[:format].downcase) || Rouge::Lexers::PlainText).new
        @builder << formatter.format(lexer.lex(m[:description]))
      end
    end
  end

  def source(code, messages)
    @builder.div(id: 'editor-result') do
      @builder.text! code
    end
    @builder << "<script>$(function () {dodona.loadResultEditor('#{@programming_language}', #{messages.to_json});});</script>"
  end

  def init_js
    @builder.script do
      @builder << 'dodona.initSubmissionShow();'
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
    output = (test[:expected].to_s || '') + "\n" + (test[:generated].to_s || '')
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
    @builder.span('', class: 'glyphicon glyphicon-ok')
  end

  def icon_wrong
    @builder.span('', class: 'glyphicon glyphicon-remove')
  end

  def icon_warning
    @builder.span('', class: 'glyphicon glyphicon-exclamation-sign')
  end

  def icon_error
    @builder.span('', class: 'glyphicon glyphicon-remove-sign')
  end

  def icon_info
    @builder.span('', class: 'glyphicon glyphicon-info-sign')
  end
end
