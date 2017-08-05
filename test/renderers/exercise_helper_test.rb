

require 'test_helper'

class ExerciseHelperTest < ActiveSupport::TestCase
  setup do
    @exercise = create :exercise
  end
end

class MediaPathAbsolutizerTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @exercise = create :exercise
    @path = exercise_path(:en, @exercise)
  end

  test 'substitute multiple lines' do
    test_html = "<img alt='eend' src='media/duck.jpg'>\n" \
                "<a href='media/page.html'>Text</a>\n" \
                "<img alt='nottosubstitute' src='mediaz.png'>\n" \
                "<a href='http://google.com'>Google</a>\n" \
                "<a href='./media/path/to/stuff.png'>stuff</a>\n"
    res = ExerciseHelper::DescriptionRenderer.absolutize_media_paths test_html, @path
    expected = "<img alt='eend' src='#{@path}/media/duck.jpg'>\n" \
               "<a href='#{@path}/media/page.html'>Text</a>\n" \
               "<img alt='nottosubstitute' src='mediaz.png'>\n" \
               "<a href='http://google.com'>Google</a>\n" \
               "<a href='#{@path}/media/path/to/stuff.png'>stuff</a>\n"
    assert_equal expected, res
  end

  test 'media paths should be substituted' do
    testcases = {
      "<img src='media/path/to/photo.jpg' alt='photo' width='300'>":
        "<img src='#{@path}/media/path/to/photo.jpg' alt='photo' width='300'>",
      "<img src=\"media/path/to/photo.jpg\" alt=\"photo\" width=\"300\">":
        "<img src=\"#{@path}/media/path/to/photo.jpg\" alt=\"photo\" width=\"300\">",
      "<a href='media/link.html'><sup>LINK</sup></a>":
        "<a href='#{@path}/media/link.html'><sup>LINK</sup></a>",
      "<img src='./media/path/to/photo.jpg' alt='photo' width='300'>":
        "<img src='#{@path}/media/path/to/photo.jpg' alt='photo' width='300'>",
      "<a href='./media/link.html'><sup>LINK</sup></a>":
        "<a href='#{@path}/media/link.html'><sup>LINK</sup></a>",
      "<a href='./media/link.html' disabled><sup>LINK</sup></a>":
        "<a href='#{@path}/media/link.html' disabled><sup>LINK</sup></a>"
    }.stringify_keys
    testcases.each do |tag, expected|
      res = ExerciseHelper::DescriptionRenderer.absolutize_media_paths tag, @path
      assert_equal expected, res
    end
  end

  test 'non-media paths should not be substituted' do
    testcases = [
      "<img src='image.png' alt='random image'>",
      "<img src=\"image.png\" alt=\"random image\">",
      "<img src='http://media.com/img.png' alt='random image'>",
      "<img src='MEDIA/PATH/IN/CAPS.jpg' alt='random image'>",
      "<a href='localhost:3000'>media/path.jpg</a>",
      "<img src='img.jpg' alt='media image'>",
      "Just some random text about media/mediums.",
      "Text with media/page.html",
      "Put your files in the ./media/stuff.folder",
    ]
    testcases.each do |tag|
      res = ExerciseHelper::DescriptionRenderer.absolutize_media_paths tag, @path
      assert_equal tag, res
    end
  end
end
