module FilterableByCourseLabels
  extend ActiveSupport::Concern

  class_methods do
    # Creates a scope for course_labels, with the name `by_course_labels`
    # It also creates a method `course_labels_filter_options`
    # that returns the possible values for the column, with the count of each value
    # This is a special case of the filterable_by method of the Filterable concern,
    # as the course_id is required to get the course_labels
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
