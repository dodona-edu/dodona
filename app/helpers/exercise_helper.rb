module ExerciseHelper
  def exercise_anchor(exercise)
    '#'.concat exercise_anchor_id(exercise)
  end

  def exercise_anchor_id(exercise)
    "exercise-#{exercise.id}"
  end

  # returns a list with as the first item the description of an execise
  # and as second item a hash of footnote indexes mapped on their url
  def exercise_description_footnotes_and_first_image(exercise)
    renderer = DescriptionRenderer.new(exercise, request)
    [renderer.description_html, renderer.footnote_urls, renderer.first_image]
  end

  def description_iframe(exercise)
    id = "exercise-description-#{exercise.id}"
    url = description_exercise_url(exercise,
                                   token: exercise.access_token,
                                   dark: session[:dark])
    content_for :preload do
      tag.link rel: 'preload', href: url, as: 'document'
    end
    resizeframe = %{
      window.iFrameResize({
          heightCalculationMethod: 'bodyScroll'
        },
        '##{id}')
    }
    tag.iframe id: id,
               scrolling: 'no',
               onload: resizeframe,
               allow: 'fullscreen https://www.youtube.com https://www.youtube-nocookie.com https://player.vimeo.com/ ',
               src: url
  end

  class DescriptionRenderer
    require 'nokogiri'
    include Rails.application.routes.url_helpers
    include ApplicationHelper

    attr_reader :footnote_urls
    attr_reader :first_image

    def initialize(exercise, request)
      @exercise = exercise
      @request = request
      @description = exercise.description || ''
      @description = markdown_unsafe(@description) if exercise.description_format == 'md'
      process_html
    end

    def description_html
      @description.html_safe
    end

    # Regex matching a HTML tag which has at least one attribute
    # starting with 'media' or './media'
    # The trailing 'm' makes this regex multiline,
    # so newlines between attributes are handled correctly
    MEDIA_TAG_MATCH = %r{<.*?=['"](\.\/)?media\/.*?['"].*?>}m.freeze

    # Regex used for replacing these relative paths:
    # 1: opening quotation marks
    # 2: optional ./ (discarded)
    # 3: media url
    # 4: closing quotation marks
    MEDIA_ATTR_MATCH = %r{(=['"])(\.\/)?(media\/.*?)(['"])}.freeze

    # Replace each occurence of a relative media path with a
    # path relative to the context (base URL).
    #
    # A match within a match is used to be able to handle multiple
    # relative media paths in one tag, while making sure we only
    # substitute within tags.
    #
    # Example substitutions:
    # (with path = /nl/exercises/xxxx/)
    # <img src='media/photo.jpg'>
    #  => <img src='/nl/exercises/xxxx/media/photo.jpg'>
    # <a href='./media/page.html'>link</a>
    #  => <a href='/nl/exercises/xxxx/media/page.html'>
    def contextualize_media_paths(html, path, token)
      path += '/' unless path.ends_with? '/'
      html.gsub(MEDIA_TAG_MATCH) do |match|
        match.gsub MEDIA_ATTR_MATCH, token.present? ? "\\1#{path}\\3?token=#{token}\\4" : "\\1#{path}\\3\\4"
      end
    end

    private

    def with_nokogiri(html)
      doc = Nokogiri::HTML::DocumentFragment.parse html
      yield doc
      doc.to_html
    end

    def process_html
      rewrite_media_urls
      @description = with_nokogiri(@description) do |doc|
        add_media_captions doc
        process_url_footnotes doc
        search_for_first_image doc
      end
    end

    def add_media_captions(doc)
      doc.css('img[data-caption]').each do |img|
        caption = img.attribute('data-caption').value
        # Filter <div class="thumbcaption">???</div> away
        text = caption.gsub(%r{\s*<div.*?>(.*?)</\s*div>}, '\1')

        caption = "<figcaption class='visible-print-block'>"\
                  "#{text}</figcaption>"
        img.add_next_sibling caption
      end
    end

    # Rewrite all media urls
    def rewrite_media_urls
      @description = contextualize_media_paths @description, exercise_path(nil, @exercise), @exercise.access_private? ? @exercise.access_token : ''
    end

    # Rewrite relative url's to absulute
    # (i.e. if it is relative, rewrite it to be absolute)
    # Returns nil if the argument isn't an url
    def absolutize_url(url)
      URI.join(@request.original_url, url).to_s
    rescue URI::InvalidURIError
      nil
    end

    # Add a footnote reference after each anchor, and add the anchor href
    # to the hash of footnotes (with the footnote index as key)
    def process_url_footnotes(doc)
      @footnote_urls = {}
      i = 1
      doc.css('a').each do |anchor|
        Maybe(anchor.attribute('href')) # get href attribute
          .map(&:value) # get its value
          .map { |u| absolutize_url u } # absolutize it
          .map do |url|
          # If any of the steps above returned nil, this block isn't executed

          ref = "<sup class='footnote-url visible-print-inline'>#{i}</sup>"
          anchor.add_next_sibling ref

          @footnote_urls[i.to_s] = url
          i += 1
        end
      end
    end

    # Look for the first image in the document with a src attribute
    def search_for_first_image(doc)
      @first_image = doc.css('img')
                        .map { |i| i.attribute('src') }
                        .compact
                        .map(&method(:absolutize_url))
                        .first
    end
  end
end
