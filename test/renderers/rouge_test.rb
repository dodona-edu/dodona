require 'test_helper'
require 'builder'

class RougeTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  test 'markdown should have added class for language' do
    input_python = "```python3\ndef mysum(a, b, c);\n    return a + b + c\n```\n"
    input_java = "```java\npublic int mySum(int a, int b, int c){\n    return a + b + c;\n}\n```\n"
    input_javascript = "```javascript\nfunction mySum(a, b, c){\n    return a + b + c;\n}\n```\n"

    [input_python, input_java, input_javascript].each do |input|
      assert_includes markdown(input), 'class'
    end
  end

  test 'Rouge formatter and lexers should add classes' do
    input_python = { format: 'python', description: 'mysum(3, 5, 7)' }
    input_javascript = { format: 'javascript', description: "return fetch(url)\n       .then(response => response.text())\n       .then(console.log)\n       .catch(handleError);\n" }
    input_java = { format: 'java', description: 'int x = mySum(7, 9, 42);' }

    [input_java, input_python, input_javascript].each do |input|
      builder = Builder::XmlMarkup.new
      builder.span(class: "code highlighter-rouge #{input[:format]}") do
        formatter = Rouge::Formatters::HTML.new(wrap: false)
        lexer = (Rouge::Lexer.find(input[:format].downcase) || Rouge::Lexers::PlainText).new
        builder << formatter.format(lexer.lex(input[:description]))
      end

      assert_includes builder.html_safe, 'class'
    end
  end
end
