require 'nokogiri'

module ExerciseHelper
  # returns a list with as the first item the description of an execise
  # and as second item a hash of footnote indexes mapped on their url
  def exercise_description_and_footnotes(exercise)
    renderer = DescriptionRenderer.new(exercise, request)
    [renderer.description_html, renderer.footnote_urls]
  end

  class DescriptionRenderer
    include Rails.application.routes.url_helpers

    attr_reader :footnote_urls

    def initialize(exercise, request)
      @exercise = exercise
      @request = request
      @description = exercise.description || ''
      @description = markdown(@description) if exercise.description_format == 'md'
      process_html
    end

    def description_html
      @description.html_safe
    end

    # Groups:
    # 1: part between the opening < and '/"
    # 2: optional ./
    # 3: media url (ex: media/photos/photo.png)
    # 4: part between the closing '/" and >
    #
    # The trailing 'm' makes this regex multiline,
    # so newlines between attributes are handled correctly
    MEDIA_MATCH = %r{(<.*?=['"])(\.\/)?(media\/.*?)(['"].*?>)}m

    # Replace each occurence of a relative media path with a
    # path relative to the context (base URL).
    #
    # Example substitutions:
    # (with path = /nl/exercises/xxxx/)
    # <img src='media/photo.jpg'>
    #  => <img src='/nl/exercises/xxxx/media/photo.jpg'>
    # <a href='./media/page.html'>link</a>
    #  => <a href='/nl/exercises/xxxx/media/page.html'>
    def contextualize_media_paths(html, path)
      path += '/' unless path.ends_with? '/'
      html.gsub(MEDIA_MATCH, "\\1#{path}\\3\\4")
    end

    private

    def process_html
      rewrite_media_urls
      process_url_footnotes
    end

    # Convert source to html
    def markdown(source)
      source ||= ''
      Kramdown::Document.new(source,
                             input: 'GFM',
                             hard_wrap: false, syntax_highlighter:
                             'rouge',
                             math_engine_opts: { preview: true }).to_html.html_safe
    end

    # Rewrite all media urls
    def rewrite_media_urls
      @description = contextualize_media_paths @description, exercise_path(nil, @exercise)
    end

    # Rewrite relative url's to absulute
    # (i.e. if it is relative, rewrite it to be absolute)
    def absolutize_url(url)
      URI.join(@request.original_url, url).to_s
    end

    # Add a footnote reference after each anchor, and add the anchor href
    # to the hash of footnotes (with the footnote index as key)
    def process_url_footnotes
      @doc = Nokogiri::HTML::DocumentFragment.parse @description
      @footnote_urls = {}
      i = 1
      @doc.css('a').each do |anchor|
        ref = "<sup class='footnote-url visible-print-inline'>#{i}</sup>"
        anchor.add_next_sibling ref
        @footnote_urls[i.to_s] = absolutize_url anchor.attribute('href').value
        i += 1
      end
      @description = @doc.to_html
    end
  end
end
