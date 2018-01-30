require 'test_helper'

# A test that just runs renderers on input satisfying the schema,
# and test whether they don't crash.
class RenderersTest < ActiveSupport::TestCase
  FILES_LOCATION = Rails.root.join('test', 'files')

  def run_renderer(renderer, file_name)
    json = (FILES_LOCATION + file_name).read
    submission = create :submission, result: json
    renderer.new(submission, submission.user).parse
  end

  def assert_no_xss(html)
    assert_no_match %r{<script>alert.*</script>}, html, 'vulnerable to xss'
  end

  test 'feedback table renderer' do
    assert_no_xss run_renderer(FeedbackTableRenderer, 'output.json')
  end

  test 'pythia renderer' do
    assert_no_xss run_renderer(PythiaRenderer, 'pythia_output.json')
  end
end
