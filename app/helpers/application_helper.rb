module ApplicationHelper
  def markdown(source)
    Kramdown::Document.new(source, input: 'GFM', syntax_highlighter: 'rouge').to_html.html_safe
  end
end
