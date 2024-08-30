module Filterable
  extend ActiveSupport::Concern

  included do
    before_save :set_search
    scope :by_filter, ->(filter) { filter.split.map(&:strip).compact_blank.inject(self) { |query, part| query.where("#{table_name}.search LIKE ?", "%#{part}%") } }
  end
end
