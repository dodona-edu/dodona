class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def markdown(source)
    source ||= ''
    Kramdown::Document.new(source, input: 'GFM', hard_wrap: false, syntax_highlighter: 'rouge', math_engine_opts: { preview: true }).to_html.html_safe
  end

  def self.human_enum_name(enum_name, enum_value, options = {})
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}", options)
  end
end
