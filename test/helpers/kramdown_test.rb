require 'test_helper'

class KramdownTest < Minitest::Test
  include ApplicationHelper

  def test_mermaid_works
    markdown = <<~EOS
      This is an example of codeblocks using mermaid:

      ```mermaid
      graph TD;
        MoreUsers-->MorePipeline;
        MorePipeline-->MoreRevenue;
        MoreRevenue-->MoreFeatures;
        MoreFeatures-->MoreUsers;
      ```
    EOS

    expected_html = <<~EOS
      <p>This is an example of codeblocks using mermaid:</p>

      <div class="mermaid">graph TD;
        MoreUsers-->MorePipeline;
        MorePipeline-->MoreRevenue;
        MoreRevenue-->MoreFeatures;
        MoreFeatures-->MoreUsers;
      </div>
    EOS

    actual_html = markdown_unsafe(markdown)

    assert_equal expected_html, actual_html
  end
end
