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
    dark = current_user.present? && session[:dark]
    id = "exercise-description-#{exercise.id}"
    url = description_exercise_url(exercise,
                                   token: exercise.access_token,
                                   dark: dark).html_safe
    resizeframe = %{
      window.iFrameResize({
          heightCalculationMethod: 'bodyScroll',
          onResized: dodona.afterResize,
        },
        '##{id}')
    }
    tag.iframe id: id,
               scrolling: 'no',
               onload: resizeframe,
               allow: 'fullscreen https://www.youtube.com https://www.youtube-nocookie.com https://player.vimeo.com/ ',
               src: url,
               height: '500px'
  end

  class DescriptionRenderer
    require 'nokogiri'
    include Rails.application.routes.url_helpers
    include ApplicationHelper
    include ExerciseHelper

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

    private

    def with_nokogiri(html)
      doc = Nokogiri::HTML::DocumentFragment.parse html
      yield doc
      doc.to_html
    end

    def process_html
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
