module ApplicationHelper
  def custom_icon(name, **options)
    content_tag :i, class: "custom-material-icons #{name} #{options[:class]}" do
      render partial: "application/icons/#{name}"
    end
  end

  def exercise_scoped_url(exercise: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if exercise.nil?

    if series.present?
      course ||= series.course
      course_series_exercise_url(I18n.locale, course, series, exercise, options)
    elsif course.present?
      course_exercise_url(I18n.locale, course, exercise, options)
    else
      exercise_url(I18n.locale, exercise, options)
    end
  end

  def exercise_scoped_path(exercise: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if exercise.nil?

    if series.present?
      course ||= series.course
      course_series_exercise_path(I18n.locale, course, series, exercise, options)
    elsif course.present?
      course_exercise_path(I18n.locale, course, exercise, options)
    else
      exercise_path(I18n.locale, exercise, options)
    end
  end

  def edit_exercise_scoped_path(exercise: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if exercise.nil?

    if series.present?
      course ||= series.course
      edit_course_series_exercise_path(I18n.locale, course, series, exercise, options)
    elsif course.present?
      edit_course_exercise_path(I18n.locale, course, exercise, options)
    else
      edit_exercise_path(I18n.locale, exercise, options)
    end
  end

  def info_exercise_scoped_path(exercise: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if exercise.nil?

    if series.present?
      course ||= series.course
      info_course_series_exercise_path(I18n.locale, course, series, exercise, options)
    elsif course.present?
      info_course_exercise_path(I18n.locale, course, exercise, options)
    else
      info_exercise_path(I18n.locale, exercise, options)
    end
  end

  def submissions_scoped_path(exercise: nil, series: nil, course: nil, options: nil)
    if exercise.nil?
      submissions_path(I18n.locale, options)
    elsif series.present?
      course ||= series.course
      course_series_exercise_submissions_path(I18n.locale, course, series, exercise, options)
    elsif course.present?
      course_exercise_submissions_path(I18n.locale, course, exercise, options)
    else
      exercise_submissions_path(I18n.locale, exercise, options)
    end
  end

  def navbar_link(options)
    return unless options.delete(:if)

    url = options.delete(:url)
    if current_page?(url)
      options[:class] ||= ''
      options[:class] += ' active'
    end
    options[:'data-toggle'] = 'tooltip'
    options[:'data-placement'] = 'bottom'

    locals = {
      title: options.delete(:title),
      icon: options.delete(:icon),
      custom_icon_name: options.delete(:custom_icon),
      url: url,
      link_options: options
    }

    render partial: 'navbar_link', locals: locals
  end

  def activatable_link_to(url, options = nil)
    if current_page?(url)
      options ||= {}
      if options[:class]
        options[:class] += ' active'
      else
        options[:class] = 'active'
      end
    end
    link_to url, options do
      yield
    end
  end

  def clipboard_button_for(selector)
    selector = selector.to_s
    selector.prepend('#') unless selector.starts_with?('#')
    button_tag class: 'btn btn-default',
               type: 'button',
               title: t('js.copy-to-clipboard'),
               data: { clipboard_target: selector } do
      tag.i(class: 'mdi mdi-clipboard-text mdi-18')
    end
  end

  def markdown_unsafe(source)
    source ||= ''
    Kramdown::Document.new(source,
                           input: 'GFM',
                           hard_wrap: false,
                           syntax_highlighter: 'rouge',
                           math_engine_opts: { preview: true })
                      .to_html
                      .html_safe
  end

  def sanitize(html)
    tags = Rails::Html::SafeListSanitizer.allowed_tags.to_a
    tags += %w[table thead tbody tr td th colgroup col style svg circle line rect]
    attributes = Rails::Html::SafeListSanitizer.allowed_attributes.to_a
    attributes += %w[style target data-toggle data-parent data-tab data-line data-element id x1 y1 x2 y2 stroke stroke-width fill cx cy r]
    # Filteres allowed tags and attributes
    sanitized = ActionController::Base.helpers.sanitize html,
                                                        tags: tags,
                                                        attributes: attributes
    # If an anchor has a target, disable the referer
    doc = Nokogiri::HTML::DocumentFragment.parse(sanitized)
    doc.css('a[target*=\'_blank\']').each do |a|
      a['rel'] = 'noopener noreferrer'
    end
    doc.to_html.html_safe
  end

  def markdown(source)
    sanitize markdown_unsafe(source)
  end

  def escape_double_quotes(string)
    string.gsub('"', '\"')
  end

  def submission_status_icon(submission, size = 18)
    icon, color = {
      nil => %w[remove default],
      'correct' => %w[check correct],
      'wrong' => %w[close wrong],
      'time limit exceeded' => %w[alarm wrong],
      'running' => %w[timer-sand-empty default],
      'queued' => %w[timer-sand-empty default],
      'runtime error' => %w[flash wrong],
      'compilation error' => %w[flash-circle wrong],
      'memory limit exceeded' => %w[memory wrong]
    }[submission&.status] || %w[alert warning]
    "<i class=\"mdi mdi-#{icon} mdi-#{size} colored-#{color}\"></i>".html_safe
  end

  def options_for_enum(object, enum)
    options = enums_to_translated_options_array(object.class.name, enum.to_s)
    options_for_select(options, object.send(enum))
  end

  def enums_to_translated_options_array(klass, enum)
    klass.classify.safe_constantize.send(enum.pluralize).map do |key, _value|
      [I18n.t("activerecord.enums.#{klass.downcase}.#{enum}.#{key}").humanize, key]
    end
  end

  class BootstrapLinkRenderer < ::WillPaginate::ActionView::LinkRenderer
    protected

    def html_container(html)
      tag :ul, html, container_attributes
    end

    def page_number(page)
      tag :li, link(page, page, rel: rel_value(page)), class: ('active' if page == current_page)
    end

    def gap
      tag :li, link('&hellip;', '#'), class: 'disabled'
    end

    def previous_or_next_page(page, text, classname)
      tag :li, link(text, page || '#'), class: [classname[0..3], classname, ('disabled' unless page)].join(' ')
    end
  end

  class AjaxLinkRenderer < ::WillPaginate::ActionView::LinkRenderer
    def initialize
      # @base_url_params.delete(:format)
    end

    protected

    def html_container(html)
      tag :ul, html, container_attributes
    end

    def page_number(page)
      tag :li, link(page, page, rel: rel_value(page), "data-remote": true), class: ('active' if page == current_page)
    end

    def gap
      tag :li, link('&hellip;', '#'), class: 'disabled'
    end

    def previous_or_next_page(page, text, classname)
      tag :li, link(text, page || '#', "data-remote": true), class: [classname[0..3], classname, ('disabled' unless page)].join(' ')
    end
  end

  def page_navigation_links(pages, remote = false, controller = '', params = {}, action = 'index')
    if remote
      will_paginate(pages, class: 'pagination', inner_window: 2, outer_window: 0, renderer: AjaxLinkRenderer, previous_label: '&larr;'.html_safe, next_label: '&rarr;'.html_safe, params: { controller: controller, action: action, format: nil }.merge(params))
    else
      will_paginate(pages, class: 'pagination', inner_window: 2, outer_window: 0, renderer: BootstrapLinkRenderer, previous_label: '&larr;'.html_safe, next_label: '&rarr;'.html_safe, params: { format: nil }.merge(params))
    end
  end
end
