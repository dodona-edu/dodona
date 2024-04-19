module HasFilter
  extend ActiveSupport::Concern

  class_methods do
    def has_filter(name, color, multi: false)
      if multi
        has_scope "by_#{name}", as: name, type: :array, if: ->(this) { this.params[name].is_a?(Array) }
      else
        has_scope "by_#{name}", as: name
      end

      @@filters ||= []
      @@filters << [name, multi, color]
    end
  end
  def filters(target)
    @@filters.map do |filter, multi, color|
      scope_params = params.except(:controller, :action, :page)
      scope_params = scope_params.except(filter) unless multi
      {
        param: filter,
        data: apply_scopes(target, scope_params).send("#{filter}_filter_options"),
        multi: multi,
        color: color
      }
    end
  end
end
