module Filterable
  extend ActiveSupport::Concern

  included do
    before_save :set_search
    scope :by_filter, ->(filter) { filter.split.map(&:strip).select(&:present?).inject(self) { |query, part| query.where("#{table_name}.search LIKE ?", "%#{part}%") } }
  end

  class_methods do
    # Creates a scope for the column, with the name `by_#{column}`
    # It also creates a method `count_by_#{column}` that returns the count, by unique value, for the column
    # params:
    # +name+:: The name of the scope
    # +column+:: The column to create the scope for
    # +associations+:: The associations to include in the scope
    # +valueCheck+:: A lambda that must return true for a value, otherwise the scope will return an empty relation
    def filterable_by(name, column: name, associations: [], value_check: ->(value) { true })
      scope "by_#{name}", lambda { |value|
        if value_check.call(value)
          includes(associations).where(column => value)
        else
          none
        end
      }

      define_singleton_method("count_by_#{name}") do
        group(column).count
      end


    end
  end
end
