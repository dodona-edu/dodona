require 'test_helper'

class ExerciseHelperTest < ActiveSupport::TestCase
  def check_desc_and_footnotes(exercise)
    with_renderer_for exercise do |r|
      check_description r.description_html, exercise
      check_footnotes r.footnote_urls
    end
  end

  def check_description(description, exercise)
    expected = <<~EOS
      <h2 id="los-deze-oefening-op">Los deze oefening op</h2>
      <p><img src="/exercises/#{exercise.id}/media/img.jpg" alt="media-afbeelding">
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

class MediaPathContextualizerTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @exercise = create :exercise
    @path = exercise_path(:en, @exercise)
    @renderer = ExerciseHelper::DescriptionRenderer.new(@exercise, nil)
  end

  test 'substitute multiple lines' do
    test_html = "<img alt='eend' src='media/duck.jpg'>\n" \
                "<a href='media/page.html'>Text</a>\n" \
                "<a href=\"media/page.html\">Text</a>\n" \
                "<img alt='nottosubstitute' src='mediaz.png'>\n" \
                "<a href='http://google.com'>Google</a>\n" \
                "<a href='./media/path/to/stuff.png'>stuff</a>\n"
    res = @renderer.contextualize_media_paths test_html, @path, nil
    expected = "<img alt='eend' src='#{@path}media/duck.jpg'>\n" \
               "<a href='#{@path}media/page.html'>Text</a>\n" \
               "<a href=\"#{@path}media/page.html\">Text</a>\n" \
               "<img alt='nottosubstitute' src='mediaz.png'>\n" \
               "<a href='http://google.com'>Google</a>\n" \
               "<a href='#{@path}media/path/to/stuff.png'>stuff</a>\n"
    assert_equal expected, res
  end

  test 'media paths should be substituted' do
    testcases = {
      "<img src=\"media/path/to/photo1.jpg\" alt=\"photo\" width=\"300\">":
          "<img src=\"#{@path}media/path/to/photo1.jpg\" alt=\"photo\" width=\"300\">",
      "<img src='media/path/to/photo.jpg' alt='photo' width='300'>":
          "<img src='#{@path}media/path/to/photo.jpg' alt='photo' width='300'>",
      "<img src=\"media/path/to/photo.jpg\" alt=\"photo\" width=\"300\">":
          "<img src=\"#{@path}media/path/to/photo.jpg\" alt=\"photo\" width=\"300\">",
      "<a href='media/link.html'><sup>LINK</sup></a>":
          "<a href='#{@path}media/link.html'><sup>LINK</sup></a>",
      "<img src='./media/path/to/photo.jpg' alt='photo' width='300'>":
          "<img src='#{@path}media/path/to/photo.jpg' alt='photo' width='300'>",
      "<a href='./media/link.html'><sup>LINK</sup></a>":
          "<a href='#{@path}media/link.html'><sup>LINK</sup></a>",
      "<a href='./media/link.html' disabled><sup>LINK</sup></a>":
          "<a href='#{@path}media/link.html' disabled><sup>LINK</sup></a>",
      "<img alt=\"ISBN\" data-caption=\" <div class=&quot;thumbcaption&quot;> ISBN in tekst en streepjescode</div> \" src=\"media/ISBN.gif\" title=\"ISBN\" height=\"140\">":
          "<img alt=\"ISBN\" data-caption=\" <div class=&quot;thumbcaption&quot;> ISBN in tekst en streepjescode</div> \" src=\"#{@path}media/ISBN.gif\" title=\"ISBN\" height=\"140\">",
      "<img alt=\"ISBN\"\n data-caption=\" <div class=&quot;thumbcaption&quot;> ISBN in tekst en streepjescode</div> \"\n src=\"media/ISBN.gif\"\n title=\"ISBN\"\n height=\"140\">":
          "<img alt=\"ISBN\"\n data-caption=\" <div class=&quot;thumbcaption&quot;> ISBN in tekst en streepjescode</div> \"\n src=\"#{@path}media/ISBN.gif\"\n title=\"ISBN\"\n height=\"140\">"
    }.stringify_keys
    testcases.each do |tag, expected|
      res = @renderer.contextualize_media_paths tag, @path, nil
      assert_equal expected, res
    end
  end

  test 'non-media paths should not be substituted' do
    testcases = [
      "<img src='image.png' alt='random image'>",
      '<img src="image.png" alt="random image">',
      "<img src='http://media.com/img.png' alt='random image'>",
      "<img src='MEDIA/PATH/IN/CAPS.jpg' alt='random image'>",
      "<a href='localhost:3000'>media/path.jpg</a>",
      "<img src='img.jpg' alt='media image'>",
      'Just some random text about media/mediums.',
      'Text with media/page.html',
      'Put your files in the ./media/stuff.folder'
    ]
    testcases.each do |tag|
      res = @renderer.contextualize_media_paths tag, @path, nil
      assert_equal tag, res
    end
  end

  test 'multiple paths should be substituted' do
    testcase = '<img data-large="media/cromwell.jpg" src="media/cromwell.thumb.jpg" alt="Oliver Cromwell" title="Oliver Cromwell" height="55px">'
    expected = "<img data-large=\"#{@path}media/cromwell.jpg\" src=\"#{@path}media/cromwell.thumb.jpg\" alt=\"Oliver Cromwell\" title=\"Oliver Cromwell\" height=\"55px\">"
    res = @renderer.contextualize_media_paths testcase, @path, nil
    assert_equal expected, res
  end
end
