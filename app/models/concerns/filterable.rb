module Filterable
  extend ActiveSupport::Concern

  included do
    before_save :set_search
    scope :by_filter, ->(filter) { filter.split(' ').map(&:strip).select(&:present?).inject(self) {|query, part| query.where('search LIKE ? ', "%#{part}%")} }
  end

end
