require 'test_helper'
require 'builder'

class FeedbackCodeRendererTest < ActiveSupport::TestCase
  test 'No weird carriage return or linefeeds in the generated html' do
    programming_language = 'python'
    examples = [
      "print(x)\nprint(y)\n",
      "# First line comment\nprint(5)\nprint(6)",
      "# Doctest\n\"\"\"\n>>> 5 + 4\n9\n\"\"\"",
      "def plus(n, m):\n\treturn n+m\n\nprint(plus(5, 4))"
    ]

    examples.each do |code_orig|
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

  test 'Multiple instances result in unique html' do
    programming_language = 'python'
    tables = 5.times.collect { FeedbackCodeRenderer.new('print(5)', programming_language).add_code.html }

    assert_equal tables.uniq, tables
  end
end
