# This concern allows models to define scopes for filtering by columns
# These scopes are created with the name `by_#{column}`
# and a correlating function that counts the possible values for the column is also created
module Filterable
  extend ActiveSupport::Concern

  class_methods do
    # Creates a scope called by_filter that searches for the give value in the search column
    # Search should be a string column defined in the model
    # It will be set to the concatenation of the values of the columns passed to the search_by method
    # This is useful for searching for a value in multiple columns in an efficient way
    # params:
    # +columns+:: The columns to search for
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
    # +multi+:: If the scope should accept multiple values
    # +is_enum+:: If the column is an enum
    # +model+:: If the column is a foreign key, the model to use to get the human readable name for the column values
    # +name_hash+:: a lambda that takes a list af column values and returns a hash with the human readable name for each column value
    def filterable_by(name, column: name, associations: [], multi: false, is_enum: false, model: nil, name_hash: nil) # rubocop:disable Metrics/ParameterLists
      value_check = if is_enum
                      # We should only allow filtering with valid options in the enum
                      ->(value) { value.in? send(column.to_s.pluralize.to_s) }
                    elsif multi
                      # If the scope accepts multiple values, the values should be an array
                      ->(value) { value.is_a?(Array) }
                    else
                      ->(_) { true }
                    end

      name_hash ||= if is_enum
                      # If the column is an enum, we should use the human readable name for the values
                      ->(values) { values.index_with { |s| human_enum_name(column.to_s.pluralize.to_s, s) } }
                    elsif model
                      # If the column is a foreign key, we should use the name of the object
                      ->(values) { model.where(id: values).to_h { |s| [s.id, s.name] } }
                    else
                      # Otherwise, we should just use the value itself
                      ->(values) { values.to_h { |s| [s, s] } }
                    end

      scope "by_#{name}", lambda { |value|
        if value_check.call(value)
          scope = joins(associations).where(column => value)
          # If the scope accepts multiple values, we should only return the results that match all the values
          # This is done by grouping the results by id and checking if the count of distinct values is equal to the number of values
          # To avoid the group by clause to impact future scopes, we reselect the currently filtered elements by id
          scope = unscoped.where(id: scope.group(:id).having("COUNT(DISTINCT(#{column})) = ?", value.uniq.length).select(:id)) if multi
          scope
        else
          none
        end
      }

      # The method that returns the possible values for the column
      # It returns a list of hashes with the id, name and count of each value
      define_singleton_method("#{name}_filter_options") do
        count = joins(associations).group(column).count

        names = name_hash.call(count.keys)

        count.map { |key, value| { id: key.to_s, name: names[key].to_s, count: value } }
             .filter { |option| option[:name].present? } # Remove empty values
      end
    end

    # Creates a scope for course_labels, with the name `by_course_labels`
    # It also creates a method `course_labels_filter_options`
    # that returns the possible values for the column, with the count of each value
    # This is a special case of the filterable_by method, as the course_id is required to get the course_labels
    def filterable_by_course_labels(through_user: false)
      if through_user
        has_many :course_memberships, through: :user
        has_many :course_labels, through: :course_memberships
      end

      scope :by_course_labels, lambda { |labels, course_id|
        unscoped.where(id: select(:id))
                .joins(:course_memberships)
                .where(course_memberships: { id: CourseMembership.where(course_id: course_id).by_course_labels(labels) })
      }

      define_singleton_method('course_labels_filter_options') do |course_id|
        count = unscoped.where(id: select(:id))
                        .joins(:course_labels)
                        .where(course_memberships: { course_id: course_id })
                        .group('course_labels.name')
                        .count

        count.map { |key, value| { id: key.to_s, name: key.to_s, count: value } }
             .filter { |option| option[:name].present? }
      end
    end
  end
end
