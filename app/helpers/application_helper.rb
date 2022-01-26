module ApplicationHelper
  def custom_icon(name, **options)
    tag.i class: "custom-material-icons #{name} #{options[:class]}" do
      render partial: "application/icons/#{name}"
    end
  end

  def sandbox_url
    "#{request.protocol}#{Rails.configuration.sandbox_host}:#{request.port}"
  end

  def activity_scoped_url(activity: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if activity.nil?

    if series.present?
      course ||= series.course
      course_series_activity_url(I18n.locale, course, series, activity, options)
    elsif course.present?
      course_activity_url(I18n.locale, course, activity, options)
    else
      activity_url(I18n.locale, activity, options)
    end
  end

  def activity_scoped_path(activity: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if activity.nil?

    if series.present?
      course ||= series.course
      course_series_activity_path(I18n.locale, course, series, activity, options)
    elsif course.present?
      course_activity_path(I18n.locale, course, activity, options)
    else
      activity_path(I18n.locale, activity, options)
    end
  end

  def edit_activity_scoped_path(activity: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if activity.nil?

    if series.present?
      course ||= series.course
      edit_course_series_activity_path(I18n.locale, course, series, activity, options)
    elsif course.present?
      edit_course_activity_path(I18n.locale, course, activity, options)
    else
      edit_activity_path(I18n.locale, activity, options)
    end
  end

  def info_activity_scoped_path(activity: nil, series: nil, course: nil, options: nil)
    raise 'Exercise should not be nil' if activity.nil?

    if series.present?
      course ||= series.course
      info_course_series_activity_path(I18n.locale, course, series, activity, options)
    elsif course.present?
      info_course_activity_path(I18n.locale, course, activity, options)
    else
      info_activity_path(I18n.locale, activity, options)
    end
  end

  def submissions_scoped_path(exercise: nil, series: nil, course: nil, options: nil)
    if exercise.nil?
      submissions_path(I18n.locale, options)
    elsif series.present?
      course ||= series.course
      course_series_activity_submissions_path(I18n.locale, course, series, exercise, options)
    elsif course.present?
      course_activity_submissions_path(I18n.locale, course, exercise, options)
    else
      activity_submissions_path(I18n.locale, exercise, options)
    end
  end

  def activity_read_states_scoped_path(content_page: nil, series: nil, course: nil, options: nil)
    if content_page.nil?
      activity_read_states_path(I18n.locale, options)
    elsif series.present?
      course ||= series.course
      course_series_activity_activity_read_states_path(I18n.locale, course, series, content_page, options)
    elsif course.present?
      course_activity_activity_read_states_path(I18n.locale, course, content_page, options)
    else
      activity_activity_read_states_path(I18n.locale, content_page, options)
    end
  end

  def navbar_link(options)
    return unless options.delete(:if)

    url = options.delete(:url)
    if current_page?(url)
      options[:class] ||= ''
      options[:class] += ' active'
    end
    options[:'data-bs-toggle'] = 'tooltip'
    options[:'data-bs-placement'] = 'bottom'

    locals = {
      title: options.delete(:title),
      icon: options.delete(:icon),
      custom_icon_name: options.delete(:custom_icon),
      url: url,
      link_options: options
    }

    render partial: 'navbar_link', locals: locals
  end

  def activatable_link_to(url, options = nil, &block)
    if current_page?(url)
      options ||= {}
      if options[:class]
        options[:class] += ' active'
      else
        options[:class] = 'active'
      end
    end
    link_to url, options, &block
  end

  def clipboard_button_for(selector)
    selector = selector.to_s
    selector.prepend('#') unless selector.starts_with?('#')
    button_tag class: 'btn btn-secondary',
               type: 'button',
               title: t('js.copy-to-clipboard'),
               data: { clipboard_target: selector } do
      tag.i(class: 'mdi mdi-clipboard-outline mdi-18')
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
    @tags ||= Rails::Html::SafeListSanitizer.allowed_tags.to_a + %w[table thead tbody tr td th colgroup col style svg circle line rect path summary details]
    @attributes ||= Rails::Html::SafeListSanitizer.allowed_attributes.to_a + %w[style target data-bs-toggle data-parent data-tab data-line data-element id x1 y1 x2 y2 stroke stroke-width fill cx cy r]

    # Filters allowed tags and attributes
    sanitized = ActionController::Base.helpers.sanitize html,
                                                        tags: @tags,
                                                        attributes: @attributes
    sanitized.html_safe
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
      'memory limit exceeded' => %w[memory wrong],
      'output limit exceeded' => %w[script-text wrong]
    }[submission&.status] || %w[alert warning]
    "<i class=\"mdi mdi-#{icon} mdi-#{size} colored-#{color}\"></i>".html_safe
  end

  def locale=(language_code)
    # We support BCP47 tags, but they can contain more than just the language, so extract only the language.
    language = language_code.to_s.split('-').first
    begin
      I18n.locale = language
    rescue I18n::InvalidLocale
      I18n.locale = I18n.default_locale
    end
    current_user&.update(lang: I18n.locale.to_s) if current_user&.lang != I18n.locale.to_s
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

  def flash_to_bootstrap(klass)
    {
      'notice' => 'info',
      'danger' => 'error',
      'alert' => 'warning',
      'success' => 'success'
    }[klass]
  end

  class BootstrapLinkRenderer < ::ActionView::Base::LinkRenderer
    protected

    def html_container(html)
      tag :ul, html, container_attributes
    end

    def page_number(page)
      tag :li, link(page, page, rel: rel_value(page), class: 'page-link'), class: (page == current_page ? 'active page-item' : 'page-item')
    end

    def gap
      tag :li, link('&hellip;', '#', class: 'page-link'), class: 'page-item disabled'
    end

    def previous_or_next_page(page, text, classname)
      tag :li, link(text, page || '#', class: 'page-link'), class: [classname[0..3], classname, ('disabled' unless page), 'page-item'].join(' ')
    end
  end

  class AjaxLinkRenderer < ::ActionView::Base::LinkRenderer
    protected

    def html_container(html)
      tag :ul, html, container_attributes
    end

    def page_number(page)
      tag :li, link(page, page, rel: rel_value(page), 'data-remote': true, class: 'page-link'), class: (page == current_page ? 'active page-item' : 'page-item')
    end

    def gap
      tag :li, link('&hellip;', '#', class: 'page-link'), class: 'page-item disabled'
    end

    def previous_or_next_page(page, text, classname)
      tag :li, link(text, page || '#', 'data-remote': true, class: 'page-link'), class: [classname[0..3], classname, ('disabled' unless page), 'page-item'].join(' ')
    end
  end

  # rubocop:disable Metrics/ParameterLists
  def page_navigation_links(pages, remote = false, controller = '', params = {}, action = 'index', param_name = 'page')
    if remote
      will_paginate(pages, param_name: param_name, class: 'pagination', inner_window: 2, outer_window: 0, renderer: AjaxLinkRenderer, previous_label: '&larr;'.html_safe, next_label: '&rarr;'.html_safe, params: { controller: controller, action: action, format: nil }.merge(params))
    else
      will_paginate(pages, param_name: param_name, class: 'pagination', inner_window: 2, outer_window: 0, renderer: BootstrapLinkRenderer, previous_label: '&larr;'.html_safe, next_label: '&rarr;'.html_safe, params: { format: nil }.merge(params))
    end
  end
  # rubocop:enable Metrics/ParameterLists
end
