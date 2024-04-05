module HasFilter
  extend ActiveSupport::Concern

  class_methods do
    def has_filter(name, color, multi: false)
      if multi
        has_scope "by_#{name}", as: name, type: :array
      else
        has_scope "by_#{name}", as: name
      end

      @@filters ||= []
      @@filters << [name, multi, color]
    end
  end
  def filters(target)
    @@filters.map do |filter, multi, color|
      params_without_current = params.except(:controller, :action, :page, filter)
      {
        param: filter,
        data: apply_scopes(target, params_without_current).send("#{filter}_filter_options"),
        multi: multi,
        color: color
      }
    end
  end
end
