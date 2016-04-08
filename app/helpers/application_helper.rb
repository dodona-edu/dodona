module ApplicationHelper
  def markdown(source)
    Kramdown::Document.new(source, :input => 'GFM').to_html.html_safe
  end
end
