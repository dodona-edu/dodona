module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def search_by(*columns)
      define_method(:set_search) do
        self.search = columns.map { |column| send(column) || '' }.join(' ')
      end

      before_save :set_search
      scope :by_filter, ->(filter) { filter.split.map(&:strip).select(&:present?).inject(self) { |query, part| query.where("#{table_name}.search LIKE ?", "%#{part}%") } }
    end

    # Creates a scope for the column, with the name `by_#{column}`
    # It also creates a method `#{column}_filter_options` that returns the possible values for the column, with the count of each value
    # params:
    # +name+:: The name of the scope
    # +column+:: The column to create the scope for
    # +associations+:: The associations to include in the scope
    # +value_check+:: A lambda that must return true for a value, otherwise the scope will return an empty relation
    # +name_hash+:: a lambda that takes a list af column values and returns a hash with the human readable name for each column value
    def filterable_by(name, column: name, associations: [], value_check: ->(value) { true }, name_hash: ->(values) { values.to_h { |value| [value, value] } })
      scope "by_#{name}", lambda { |value|
        if value_check.call(value)
          includes(associations).where(column => value)
        else
          none
        end
      }

      define_singleton_method("#{name}_filter_options") do
        count = group(column).count
        names = name_hash.call(count.keys)

        count.map { |key, value| { id: key, name: names[key], count: value } }
      end

    end
  end
end
