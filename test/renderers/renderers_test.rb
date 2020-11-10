require 'test_helper'

# A test that just runs renderers on input satisfying the schema,
# and test whether they don't crash.
class RenderersTest < ActiveSupport::TestCase
  FILES_LOCATION = Rails.root.join('test/files')

  def run_renderer(renderer, file_name)
    json = (FILES_LOCATION + file_name).read
    submission = create :submission, result: json, user: create(:zeus)
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

  test 'pythia\'s strip function should strip newlines' do
    renderer = PythiaRenderer.new(create(:submission), create(:user))
    assert_equal '3309..4264', renderer.strip_outer_html("<li class=\"ins\"><ins>3309..4264\n</ins></li>")
  end

  test 'should not strip for exercise marked unsafe' do
    json = FILES_LOCATION.join('output.json').read
    exercise = create :exercise
    exercise.update(allow_unsafe: true)
    submission = create :submission, result: json, user: create(:zeus), activity: exercise, status: :correct

    assert_match %r{<script>alert.*</script>}, FeedbackTableRenderer.new(submission, submission.user).parse
  end

  test 'should not strip for exercise marked unsafe (pythia)' do
    json = FILES_LOCATION.join('pythia_output.json').read
    exercise = create :exercise
    exercise.update(allow_unsafe: true)
    submission = create :submission, result: json, user: create(:zeus), activity: exercise, status: :correct

    assert_match %r{<script>alert.*</script>}, PythiaRenderer.new(submission, submission.user).parse
  end

  test 'should include exercise token if exercise rendered for is private' do
    json = FILES_LOCATION.join('output.json').read
    exercise = create :exercise
    exercise.update(access: :private)
    submission = create :submission, result: json, user: create(:zeus), activity: exercise, status: :correct

    assert_match exercise.access_token, FeedbackTableRenderer.new(submission, submission.user).parse
  end
end
