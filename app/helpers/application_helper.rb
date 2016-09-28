module ApplicationHelper
  def markdown(source)
    source ||= ''
    Kramdown::Document.new(source, input: 'GFM', syntax_highlighter: 'rouge', math_engine_opts: { preview: true }).to_html.html_safe
  end

  def escape_double_quotes(string)
    string.gsub('"', '\"')
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

  def page_navigation_links(pages, remote = false, controller = '', params = {})
    if remote
      will_paginate(pages, class: 'pagination', inner_window: 2, outer_window: 0, renderer: AjaxLinkRenderer, previous_label: '&larr;'.html_safe, next_label: '&rarr;'.html_safe, params: { controller: controller, action: 'index' }.merge(params))
    else
      will_paginate(pages, class: 'pagination', inner_window: 2, outer_window: 0, renderer: BootstrapLinkRenderer, previous_label: '&larr;'.html_safe, next_label: '&rarr;'.html_safe)
    end
  end
end
