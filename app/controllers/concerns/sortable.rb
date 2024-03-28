module Sortable
  extend ActiveSupport::Concern

  class_methods do
    def order_by(*scopes)
      string_scopes = scopes.map(&:to_s)
      has_scope :order_by, using: %i[column direction], type: :hash do |_controller, scope, value|
        column, direction = value
        if %w[ASC DESC].include?(direction) && string_scopes.include?(column)
          scope.send "order_by_#{column}", direction
        else
          scope
        end
      end
    end
  end
end
