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
    # +multi+:: If the scope should accept multiple values
    # +is_enum+:: If the column is an enum
    # +model+:: If the column is a foreign key, the model to use to get the human readable name for the column values
    # +name_hash+:: a lambda that takes a list af column values and returns a hash with the human readable name for each column value
    def filterable_by(name, column: name, associations: [], multi: false, is_enum: false, model: nil, name_hash: nil) # rubocop:disable Metrics/ParameterLists
      value_check = if is_enum
                      ->(value) { value.in? send(column.to_s.pluralize.to_s) }
                    else
                      ->(_) { true }
                    end

      name_hash ||= if is_enum
                      ->(values) { values.index_with { |s| human_enum_name(column.to_s.pluralize.to_s, s) } }
                    elsif model
                      ->(values) { model.where(id: values).to_h { |s| [s.id, s.name] } }
                    else
                      ->(values) { values.to_h { |s| [s, s] } }
                    end

      scope "by_#{name}", lambda { |value|
        if value_check.call(value) && (!multi || value.is_a?(Array))
          scope = joins(associations).where(column => value)
          scope = scope.group(:id).having("COUNT(DISTINCT(#{column})) = ?", value.uniq.length) if multi
          scope
        else
          none
        end
      }

      define_singleton_method("#{name}_filter_options") do
        count = unscoped.where(id: select(:id)).joins(associations).group(column).count

        names = name_hash.call(count.keys)

        count.map { |key, value| { id: key.to_s, name: names[key].to_s, count: value } }
             .filter { |option| option[:name].present? }
      end
    end

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
