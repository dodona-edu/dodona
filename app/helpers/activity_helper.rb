module ActivityHelper
  def activity_config_explanation(*keys)
    location = @config_locations.dig(*keys)
    if location.present?
      location = location.to_sentence if location.is_a? Array
      t '.config_set_by', file: location
    else
      t '.config_default'
    end
  end

  def activity_anchor(activity)
    '#'.concat activity_anchor_id(activity)
  end

  def activity_anchor_id(activity)
    "activity-#{activity.id}"
  end

  # Finds the paths to the previous and next activity in a series, given the
  # current activity.
  def previous_next_activity_path(series, activity)
    return [nil, nil] if series.blank?

    previous_ex = nil
    next_ex = nil

    # Function that gets the path to the activity.
    get_ex_path = ->(ex) { course_series_activity_path(I18n.locale, series.course, series.id, ex) }

    series.activity_ids.each_with_index do |series_activity_id, idx|
      next unless series_activity_id == activity.id

      previous_ex = get_ex_path.call(series.activity_ids[idx - 1]) if idx > 0
      next_ex = get_ex_path.call(series.activity_ids[idx + 1]) if idx + 1 < series.activities.length
      break
    end

    [previous_ex, next_ex]
  end

  BYTE_UNITS = {
    unit: 'B',
    thousand: 'kB',
    million: 'MB',
    billion: 'GB',
    trillion: 'TB'
  }.freeze

  # Rails doesn't think its number_to_human_bytes helper should be correct,
  # it returns Mebibytes and calls them Megabytes... sigh.
  # This custom helper at least returns actual metric units.
  def human_bytes(bytes)
    number_to_human bytes, units: BYTE_UNITS
  end

  # returns a list with as the first item the description of an activity
  # and as second item a hash of footnote indexes mapped on their url
  def activity_description_footnotes_and_first_image(activity)
    renderer = DescriptionRenderer.new(activity, request)
    [renderer.description_html, renderer.footnote_urls, renderer.first_image]
  end

  def description_iframe(activity)
    dark = current_user.present? && session[:dark]
    id = "activity-description-#{activity.id}"
    url = description_activity_url(activity,
                                   token: activity.access_token,
                                   dark: dark).html_safe
    resizeframe = %{
      window.iFrameResize({
          onResized: dodona.afterResize,
          onMessage: dodona.onFrameMessage,
          onScroll: dodona.onFrameScroll,
          inPageLinks: true,
        },
        '##{id}')
    }
    tag.iframe id: id,
               class: 'dodona-iframe',
               scrolling: 'no',
               onload: resizeframe,
               allow: 'fullscreen https://www.youtube.com https://www.youtube-nocookie.com https://player.vimeo.com/ ',
               src: url,
               height: '500px'
  end

  def starts_with_solution?(item)
    item.first.starts_with?('solution')
  end

  def compare_solutions(a, b)
    if starts_with_solution?(a) == starts_with_solution?(b)
      a <=> b
    elsif starts_with_solution?(a)
      -1
    else
      1
    end
  end

  def show_type_icon(activity, size = 18)
    if activity.exercise?
      content_tag(:i, '', class: "mdi mdi-#{activity.programming_language&.icon} mdi-#{size}", title: "#{t 'activities.index.type.exercise_language', language: activity.programming_language&.name&.titleize}")
    elsif activity.content_page?
      content_tag(:i, '', class: "mdi mdi-book-open-variant mdi-#{size}", title: "#{t 'activities.index.type.content'}")
    end
  end

  class DescriptionRenderer
    require 'nokogiri'
    include Rails.application.routes.url_helpers
    include ApplicationHelper
    include ActivityHelper

    attr_reader :footnote_urls, :first_image

    def initialize(activity, request)
      @activity = activity
      @request = request
      @description = activity.description || ''
      @description = markdown_unsafe(@description) if activity.description_format == 'md'
      process_html
    end

    def description_html
      @description.html_safe
    end

    private

    def with_nokogiri(html)
      doc = Nokogiri::HTML5::DocumentFragment.parse html
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

    # Rewrite relative url's to absolute
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
        url = anchor.attribute('href')&.value
        next if url.nil?

        url = absolutize_url(url)
        next if url.nil?

        ref = "<sup class='footnote-url visible-print-inline'>#{i}</sup>"
        anchor.add_next_sibling ref

        @footnote_urls[i.to_s] = url
        i += 1
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
