class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def markdown(source)
    Kramdown::Document.new(source, input: 'GFM', syntax_highlighter: 'rouge', math_engine_opts: { preview: true }).to_html.html_safe
  end
end
