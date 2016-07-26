module SubmissionsHelper
  class FeedbackTableRenderer
    require 'builder'

    def initialize(submission)
      @submission = JSON.parse(submission.result, symbolize_names: true)
      @builder = Builder::XmlMarkup.new
    end

    def parse
      @builder.div(class: 'feedback-table') do
        @builder.p(@submission[:description])
        tabs(@submission)
      end.html_safe
    end

    def tabs(submission)
      @builder.div(class: 'card card-nav') do
        @builder.div(class: 'card-title card-title-colored') do
          @builder.ul(class: 'nav nav-tabs') do
            submission[:groups].each_with_index do |t, i|
              @builder.li(class: ('active' if i == 0)) do
                @builder.a(t[:description].titleize, href: "##{t[:description].parameterize}", 'data-toggle': 'tab')
              end
            end
          end
        end
        @builder.div(class: 'card-supporting-text') do
          @builder.div(class: 'tab-content') do
            @submission[:groups].each_with_index { |t, i| tab(t, i == 0) }
          end
        end
      end
    end

    def tab(t, first = false)
      @builder.div(class: "tab-pane #{'active' if first}", id: t[:description].parameterize) do
        t[:groups].each { |g| group(g) } if t[:groups]
      end
    end

    def group(g)
      @builder.div(class: 'group') do
        @builder.div(class: 'description') do
          message(g[:description])
        end if g[:description]
        g[:groups].each { |tc| testcase(tc) }
      end
    end

    def testcase(tc)
      @builder.div(class: 'testcase') do
        @builder.div(class: 'description') do
          tc[:accepted] ? correct_icon : wrong_icon
          @builder << ' '
          message(tc[:description]) if tc[:description]
        end
        tc[:tests].each { |t| test(t) } if tc[:tests]
      end
    end

    def test(t)
      @builder.div(class: 'test') do
        @builder.div(class: 'description') do
          message(t[:description])
        end
        if t[:accepted]
          test_accepted(t)
        else
          test_failed(t)
        end
      end
    end

    def test_accepted(t)
      @builder.div(class: 'test-accepted') do
        # correct_icon
        @builder.span(t[:generated], class: 'output')
      end
    end

    def test_failed(t)
      @builder.div do
        diff(t)
      end
    end

    def diff(t)
      diff_unified(t)
      @builder.br
      diff_split(t)
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
      m = { format: 'plain', description: m } if m.is_a? String
      case m[:format]
      when 'plain'
        @builder.text! m[:description]
      when 'html'
        @builder << m[:description]
      when 'code'
        @builder.span(class: 'code') do
          @builder.text! m[:description]
        end
      else
        @builder.text! m[:description]
      end
    end

    def testcase_icon
      @builder.span("► ", class: 'testcase-icon')
    end

    def correct_icon
      @builder.span('', class: 'glyphicon glyphicon-ok')
    end

    def wrong_icon
      @builder.span('', class: 'glyphicon glyphicon-remove')
    end
  end
end
