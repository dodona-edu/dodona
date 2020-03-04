require 'test_helper'
require 'builder'

class FeedbackCodeRendererTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  test 'No weird carriage return or linefeeds in the generated html' do
    code_orig = "print(x)\nprint(y)\n"
    programming_language = 'python'
    renderer_orig = FeedbackCodeRenderer.new(code_orig, programming_language)
    gen_html_orig = renderer_orig.parse.html

    code = code_orig.encode(crlf_newline: true)
    renderer_crlf = FeedbackCodeRenderer.new(code, programming_language)
    gen_html_crlf = renderer_crlf.parse.html

    code = code_orig.encode(cr_newline: true)
    renderer_cr = FeedbackCodeRenderer.new(code, programming_language)
    gen_html_cr = renderer_cr.parse.html

    assert_equal gen_html_orig, gen_html_crlf
    assert_equal gen_html_orig, gen_html_cr
  end
end
