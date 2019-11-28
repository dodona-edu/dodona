require 'test_helper'

class ExerciseHelperTest < ActiveSupport::TestCase
  def check_desc_and_footnotes(exercise)
    with_renderer_for exercise do |r|
      check_description r.description_html
      check_footnotes r.footnote_urls
    end
  end

  def check_description(description)
    expected = <<~EOS
      <h2 id="los-deze-oefening-op">Los deze oefening op</h2>
      <p><img src="media/img.jpg" alt="media-afbeelding">
      <a href="https://google.com">LMGTFY</a><sup class="footnote-url visible-print-inline">1</sup>
      <a href="../123455/">Volgende oefening</a><sup class="footnote-url visible-print-inline">2</sup></p>
    EOS
    assert_equal expected, description
  end

  def check_footnotes(footnotes)
    footnote_a = footnotes.to_a
    index, content = footnote_a[0]
    assert_equal '1', index
    assert_equal 'https://google.com', content

    index, content = footnote_a[1]
    assert_equal '2', index
    assert_equal 'http://example.com/exercises/123455/', content
  end

  test 'html exercise' do
    exercise = create :exercise, :description_html
    check_desc_and_footnotes exercise
  end

  test 'md exercise' do
    exercise = create :exercise, :description_md
    check_desc_and_footnotes exercise
  end

  test 'exercise with non-url footnote should not be replaced' do
    desc = "<a href=\"javascript:(function() { alert('You clicked!') })();\">Click me!</a>"
    exercise = create :exercise, description_html_stubbed: desc

    with_renderer_for exercise do |r|
      assert r.footnote_urls.empty?
    end
  end

  test 'exercise with anchor witout href attribute' do
    desc = '<a>This is an anchor</a>'
    exercise = create :exercise, description_html_stubbed: desc

    with_renderer_for exercise do |r|
      assert r.footnote_urls.empty?
      assert_equal desc, r.description_html
    end
  end

  def with_renderer_for(exercise)
    url = "http://example.com/exercises/#{exercise.id}/"
    stubrequest = mock
    stubrequest.stubs(:original_url).returns(url)
    yield ExerciseHelper::DescriptionRenderer.new(exercise, stubrequest), url
  end
end
