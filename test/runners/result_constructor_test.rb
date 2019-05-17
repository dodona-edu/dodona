
require 'json'
require 'test_helper'
require 'result_constructor'

class ResultConstructorTest < ActiveSupport::TestCase
  MINIMAL_FULL_S =

    test 'empty output should fail' do
      assert_raises ResultConstructorError do
        construct_result([''])
      end
    end

  test 'empty json should fail' do
    assert_raises ResultConstructorError do
      construct_result(['{}'])
    end
  end

  test 'minimal full schema should be accepted' do
    assert_equal({ accepted: true, status: 'correct' }, construct_result([
      '{ "accepted": true, "status": "correct" }'
    ]))
  end

  test 'second full schema should be overwrite' do
    assert_equal({ accepted: false, status: 'wrong' }, construct_result([
      '{ "accepted": true, "status": "correct" }{ "accepted": false, "status": "wrong" }'
    ]))
  end

  test 'empty partial should be accepted' do
    assert_equal({
      accepted: true,
      status: 'correct',
      description: 'Correct'
    }, construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "close-judgement" }'
    ]))
  end

  test 'invalid json should fail' do
    assert_raises ResultConstructorError do
      construct_result(['{ Aaargh'])
    end
  end

  test 'partial output should accumulated status' do
    assert_equal({
      accepted: false,
      status: 'wrong',
      description: 'Wrong',
      groups: [{
        description: 'Tab One',
        badgeCount: 1,
        groups: [{
          accepted: true,
          groups: [{
            description: 'case 1',
            accepted: true,
            tests: [{
              expected: 'SOMETHING',
              generated: 'SOMETHING',
              accepted: true
            }]
          }]
        }, {
          accepted: false,
          groups: [{
            description: 'case 2',
            accepted: false,
            tests: [{
              expected: 'SOMETHING',
              generated: 'ELSE',
              accepted: false
            }]
          }]
        }]
      }]
    }, construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "start-tab", "title": "Tab One" }',
      '{ "command": "start-context" }',
      '{ "command": "start-testcase", "description": "case 1" }',
      '{ "command": "start-test", "expected": "SOMETHING" }',
      '{ "command": "close-test", "generated": "SOMETHING", "status": { "enum": "correct", "human": "Correct" } }',
      '{ "command": "close-testcase" }',
      '{ "command": "close-context" }',
      '{ "command": "start-context" }',
      '{ "command": "start-testcase", "description": "case 2" }',
      '{ "command": "start-test", "expected": "SOMETHING" }',
      '{ "command": "close-test", "generated": "ELSE", "status": { "enum": "wrong", "human": "Wrong" } }',
      '{ "command": "close-testcase" }',
      '{ "command": "close-context" }',
      '{ "command": "close-tab" }',
      '{ "command": "close-judgement" }'
    ]))
  end

  test 'adding message should work on every level' do
    assert_equal({
      accepted: true,
      status: 'correct',
      description: 'Correct',
      groups: [{
        description: 'Tab One',
        badgeCount: 0,
        groups: [{
          accepted: true,
          groups: [{
            description: 'case 1',
            accepted: true,
            tests: [{
              expected: 'SOMETHING',
              generated: 'SOMETHING',
              accepted: true,
              messages: ['test']
            }],
            messages: ['testcase']
          }],
          messages: ['context']
        }],
        messages: ['tab']
      }],
      messages: ['judgement']
    }, construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "append-message", "message": "judgement" }',
      '{ "command": "start-tab", "title": "Tab One" }',
      '{ "command": "append-message", "message": "tab" }',
      '{ "command": "start-context" }',
      '{ "command": "append-message", "message": "context" }',
      '{ "command": "start-testcase", "description": "case 1" }',
      '{ "command": "append-message", "message": "testcase" }',
      '{ "command": "start-test", "expected": "SOMETHING" }',
      '{ "command": "append-message", "message": "test" }',
      '{ "command": "close-test", "generated": "SOMETHING", "status": { "enum": "correct", "human": "Correct" } }',
      '{ "command": "close-testcase" }',
      '{ "command": "close-context" }',
      '{ "command": "close-tab" }',
      '{ "command": "close-judgement" }'
    ]))
  end

  test 'setting conflicting statuses should work' do
    assert_equal({
      accepted: true,
      status: 'correct',
      description: 'Correct',
      groups: [{
        description: 'Tab One',
        badgeCount: 42,
        groups: [{
          accepted: false,
          groups: [{
            description: 'case 1',
            accepted: true,
            tests: [{
              expected: 'SOMETHING',
              generated: 'SOMETHING',
              accepted: false
            }]
          }]
        }]
      }]
    }, construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "start-tab", "title": "Tab One" }',
      '{ "command": "start-context" }',
      '{ "command": "start-testcase", "description": "case 1" }',
      '{ "command": "start-test", "expected": "SOMETHING" }',
      '{ "command": "close-test", "generated": "SOMETHING", "status": { "enum": "correct", "human": "Correct" }, "accepted": false }',
      '{ "command": "close-testcase", "accepted": true }',
      '{ "command": "close-context", "accepted": false }',
      '{ "command": "close-tab", "badgeCount": 42 }',
      '{ "command": "close-judgement", "accepted": true }'
    ]))
  end

  test 'annotating the source should work' do
    assert_equal({
      accepted: true,
      status: 'correct',
      description: 'Correct',
      annotations: [
        { row: 0, column: 0, rows: 1, columns: 1, text: 'asdf', type: 'info' }
      ]
    }, construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "annotate-code", "row": 0, "text": "asdf" }',
      '{ "command": "close-judgement" }'
    ]))
  end

  test 'badgeCount counts the testcases' do
    result = construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "start-tab", "title": "Tab One" }',
      '{ "command": "start-context" }',
      '{ "command": "start-testcase", "description": "case 1" }',
      '{ "command": "close-testcase", "accepted": false }',
      '{ "command": "close-context" }',
      '{ "command": "close-tab" }',
      '{ "command": "start-tab", "title": "Tab Two" }',
      '{ "command": "start-context" }',
      '{ "command": "start-testcase", "description": "case 1" }',
      '{ "command": "close-testcase", "accepted": false }',
      '{ "command": "start-testcase", "description": "case 2" }',
      '{ "command": "close-testcase", "accepted": true }',
      '{ "command": "start-testcase", "description": "case 3" }',
      '{ "command": "close-testcase", "accepted": false }',
      '{ "command": "start-testcase", "description": "case 4" }',
      '{ "command": "close-testcase", "accepted": false }',
      '{ "command": "close-context" }',
      '{ "command": "close-tab" }',
      '{ "command": "start-tab", "title": "Tab Three" }',
      '{ "command": "start-context" }',
      '{ "command": "start-testcase", "description": "case 1" }',
      '{ "command": "close-testcase", "accepted": true }',
      '{ "command": "close-context" }',
      '{ "command": "close-tab" }',
      '{ "command": "close-judgement", "accepted": true }'
    ])
    assert_equal(1, result[:groups][0][:badgeCount])
    assert_equal(3, result[:groups][1][:badgeCount])
    assert_equal(0, result[:groups][2][:badgeCount])
  end

  test 'statuses should escalate' do
    result = construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "start-tab", "title": "Tab One" }',
      '{ "command": "start-context" }',
      '{ "command": "start-testcase", "description": "case 1" }',
      '{ "command": "start-test", "expected": "SOMETHING" }',
      '{ "command": "close-test", "generated": "SOMETHING", "status": { "enum": "correct", "human": "Correct" }, "accepted": false }',
      '{ "command": "close-testcase" }',
      '{ "command": "close-context" }',
      '{ "command": "close-tab" }',
      '{ "command": "escalate-status", "status": { "enum": "wrong", "human": "Wrong" } }',
      '{ "command": "close-judgement" }'
    ])
    assert_equal('wrong', result[:status])
    result = construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "escalate-status", "status": { "enum": "wrong", "human": "Wrong 1" } }',
      '{ "command": "escalate-status", "status": { "enum": "correct", "human": "Correct" } }',
      '{ "command": "escalate-status", "status": { "enum": "wrong", "human": "Wrong 2" } }',
      '{ "command": "close-judgement" }'
    ])
    assert_equal('wrong', result[:status])
    assert_equal('Wrong 1', result[:description])
    result = construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "escalate-status", "status": { "enum": "wrong", "human": "Wrong" } }',
      '{ "command": "escalate-status", "status": { "enum": "internal error", "human": "Internal Error" } }',
      '{ "command": "close-judgement" }'
    ])
    assert_equal('internal error', result[:status])
    result = construct_result([
      '{ "command": "start-judgement" }',
      '{ "command": "escalate-status", "status": { "enum": "wrong", "human": "Wrong" } }',
      '{ "command": "close-judgement", "status": { "enum": "runtime error", "human": "Runtime" } }'
    ])
    assert_equal('runtime error', result[:status])
  end

  private

  def construct_result(food, locale: 'en', timeout: false)
    rc = ResultConstructor.new(locale)
    food.each { |f| rc.feed f }
    rc.result(timeout)
  end
end
