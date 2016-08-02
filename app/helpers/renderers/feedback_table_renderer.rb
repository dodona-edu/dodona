class FeedbackTableRenderer
  include ApplicationHelper

  require 'builder'

  def initialize(submission, user)
    @submission = JSON.parse(submission.result, symbolize_names: true)
    @current_user = user
    @builder = Builder::XmlMarkup.new
  end

  def parse
    @builder.div(class: 'feedback-table') do
      @builder.p(@submission[:description])
      messages(@submission[:messages])
      tabs(@submission)
    end.html_safe
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
        end
      end
      @builder.div(class: 'card-supporting-text') do
        @builder.div(class: 'tab-content') do
          @submission[:groups].each_with_index { |t, i| tab(t, i) } if submission[:groups]
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
    messages(t[:messages])
    t[:groups].each { |g| group(g) } if t[:groups]
  end

  def group(g)
    @builder.div(class: 'group') do
      @builder.div(class: 'description') do
        message(g[:description])
      end if g[:description]
      messages(g[:messages])
      g[:groups].each { |tc| testcase(tc) } if g[:groups]
    end
  end

  def testcase(tc)
    @builder.div(class: 'testcase') do
      @builder.div(class: 'description') do
        tc[:accepted] ? icon_correct : icon_wrong
        @builder << ' '
        message(tc[:description]) if tc[:description]
      end
      tc[:tests].each { |t| test(t) } if tc[:tests]
      messages(tc[:messages])
    end
  end

  def test(t)
    @builder.div(class: 'test') do
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
    @builder.div(class: 'messages') do
      msgs.each do |msg|
        message(msg)
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
    @builder.div do
      diff(t)
    end
  end

  def diff(t)
    diff_heuristical(t)
  end

  def diff_heuristical(t)
    if t[:expected].scan(/\n/).count > 2
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
      @builder.div(class: 'col-xs-6') do
        @builder << d.left
      end
      @builder.div(class: 'col-xs-6') do
        @builder << d.right
      end
    end
  end

  def message(m)
    return if m.nil?
    if m[:permission]
      return if m[:permission] == 'teacher' && !@current_user.admin?
      return if m[:permission] == 'zeus' && !@current_user.zeus?
    end

    m = { format: 'plain', description: m } if m.is_a? String
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
