require 'test_helper'

class RougeTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  test 'markdown should have added class for language' do
    input_python = "```python3\ndef mysum(a, b, c);\n    return a + b + c\n```\n"
    input_java = "```java\npublic int mySum(int a, int b, int c){\n    return a + b + c;\n}\n```\n"
    input_javascript = "```javascript\nfunction mySum(a, b, c){\n    return a + b + c;\n}\n```\n"

    [input_python, input_java, input_javascript].each do |input|
      assert markdown(input).include? 'class'
    end
  end
end
