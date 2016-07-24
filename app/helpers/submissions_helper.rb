module SubmissionsHelper
  class FeedbackTableRenderer
    require 'builder'

    def initialize(submission)
      @submission = JSON.parse(submission.result)
      @builder = Builder::XmlMarkup.new
    end

    def parse
      @builder.div(class: 'feedback-table') do
        @builder.p(@submission['description'])
        @submission['groups'].each { |t| tab(t) }
      end.html_safe
    end

    def tab(t)
      @builder.div(class: 'tab') do
        @builder.div("I am a tab: #{t['description']}", class: 'description')
        t['groups'].each { |g| group(g) }
      end
    end

    def group(g)
      @builder.div(class: 'group') do
        @builder.div(g['description'], class: 'description')
        g['groups'].each { |tc| testcase(tc) }
      end
    end

    def testcase(tc)
      @builder.div(class: 'testcase') do
        @builder.div(class: 'description') do
          # if tc['accepted']
          #  correct_icon
          # else
          #  wrong_icon
          # end
          testcase_icon
          @builder.span(tc['description'])
        end
        tc['tests'].each { |t| test(t) } if tc['tests']
      end
    end

    def test(t)
      @builder.div(class: 'test') do
        @builder.div(t['description'], class: 'description')
        if t['accepted']
          test_accepted(t)
        else
          test_failed(t)
        end
      end
    end

    def test_accepted(_t)
      @builder.div(class: 'test-accepted') do
        correct_icon
        @builder.span(t['expected'], class: 'output')
      end
    end

    def test_failed(t)
      @builder.p(class: 'expected') do
        @builder.strong('expected: ')
        @builder.span(t['expected'], class: 'output')
      end
      @builder.p(class: 'generated') do
        @builder.strong('generated: ')
        @builder.span(t['generated'], class: 'output')
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
