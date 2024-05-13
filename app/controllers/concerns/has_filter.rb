module HasFilter
  extend ActiveSupport::Concern
  included do
    delegate :filter_options, to: :class
    self.filter_options = []
    def filters(target)
      filter_options.map do |name, multi|
        scope_params = params.except(:controller, :action, :page)
        scope_params = scope_params.except(name) unless multi
        {
          param: name,
          data: apply_scopes(target, scope_params).send("#{name}_filter_options"),
          multi: multi
        }
      end
    end
  end

  class_methods do
    attr_accessor :filter_options

    def has_filter(name, multi: false) # rubocop:disable Naming/PredicateName
      if multi
        has_scope "by_#{name}", as: name, type: :array, if: ->(this) { this.params[name].is_a?(Array) }
      else
        has_scope "by_#{name}", as: name
      end

      filter_options << [name, multi]
    end

    def set_filter_headers(options = {})
      after_action(options) do
        headers['X-Filters'] = @filters.to_json
      end
    end
  end
end