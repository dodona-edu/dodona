class FeedbackTableRenderer
  include ApplicationHelper

  require 'builder'

  def self.inherited(cl)
    @renderers ||= [FeedbackTableRenderer]
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
    @programming_language = submission.exercise.programming_language
  end

  def parse
    @builder.div(class: 'feedback-table') do
      @builder.div(class: 'row') do
        messages(@submission[:messages])
      end
      tabs(@submission)
    end.html_safe
  end

  def show_code_tab
    true
  end

  def tabs(submission)
    @builder.div(class: 'card card-nav') do
      @builder.div(class: 'card-title card-title-colored') do
        @builder.ul(class: 'nav nav-tabs') do
          submission[:groups].each_with_index do |t, i|
            @builder.li(class: ('active' if i.zero?)) do
              @builder.a(t[:description].titleize, href: "##{t[:description].parameterize}-#{i}", 'data-toggle': 'tab')
            end
          end if submission[:groups]
          @builder.li(class: ('active' unless submission[:groups])) do
            @builder.a(I18n.t('submissions.show.code'), href: '#code-tab', 'data-toggle': 'tab')
          end if show_code_tab
        end
      end
      @builder.div(class: 'card-supporting-text') do
        @builder.div(class: 'tab-content') do
          @submission[:groups].each_with_index { |t, i| tab(t, i) } if submission[:groups]
          @builder.div(class: "tab-pane #{'active' unless submission[:groups]}", id: 'code-tab') do
            source(@code, [])
          end if show_code_tab
        end
      end
    end
  end

  def tab(t, i)
    @builder.div(class: "tab-pane #{'active' if i.zero?}", id: "#{t[:description].parameterize}-#{i}") do
      tab_content(t)
    end
  end

  def tab_content(t)
    @diff_type = determine_tab_diff_type(t)
    messages(t[:messages])
    @builder.div(class: 'groups') do
      t[:groups].each { |g| group(g) } if t[:groups]
    end
  end

  def group(g)
    @builder.div(class: "row group #{g[:accepted] ? 'correct' : 'wrong'}") do
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
          tc[:accepted] ? icon_correct : icon_wrong
        end
        message(tc[:description]) if tc[:description]
      end
      tc[:tests].each { |t| test(t) } if tc[:tests]
      messages(tc[:messages])
    end
  end

  def test(t)
    @builder.div(class: 'col-xs-12 test') do
      @builder.div(class: 'description') do
        message(t[:description])
      end if t[:description]
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
        @builder.p(class: 'message') do
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
    if m[:permission]
      return if m[:permission] == 'staff' && !@current_user.admin?
      return if m[:permission] == 'zeus' && !@current_user.zeus?
    end
    m = { format: 'plain', description: m } if m.is_a? String
    output_message(m)
  end

  def output_message(m)
    if m[:format].in?(%w(plain text))
      @builder.text! m[:description]
    elsif m[:format].in?(%w(html))
      @builder << m[:description]
    elsif m[:format].in?(%w(markdown md))
      @builder << markdown(m[:description])
    elsif m[:format].in?(%w(code))
      @builder.span(class: 'code') do
        @builder.text! m[:description]
      end
    elsif m[:format].in?(%w(python))
      formatter = Rouge::Formatters::HTML.new(css_class: 'highlighter-rouge')
      lexer = Rouge::Lexers::Python.new
      @builder << formatter.format(lexer.lex(m[:description]))
    elsif m[:format].in?(%w(js javascript Javascript JavaScript))
      formatter = Rouge::Formatters::HTML.new(css_class: 'highlighter-rouge')
      lexer = Rouge::Lexers::Javascript.new
      @builder << formatter.format(lexer.lex(m[:description]))
    else
      @builder.text! m[:description]
    end
  end

  def source(code, messages)
    @builder.div(id: 'editor-result') do
      @builder.text! code
    end
    @builder << "<script>$(function () {loadResultEditor('#{@programming_language}', #{messages.to_json});});</script>"
  end

  def determine_tab_diff_type(tab)
    tab[:groups].each do |group|
      group[:groups].each do |testcase|
        testcase[:tests].each do |test|
          return 'unified' if determine_diff_type(test) == 'unified'
        end if testcase[:tests]
      end if group[:groups]
    end if tab[:groups]
    'split'
  end

  def determine_diff_type(test)
    output = (test[:expected] || '') + "\n" + (test[:generated] || '')
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
