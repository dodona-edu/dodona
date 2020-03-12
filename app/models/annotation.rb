class Annotation < ApplicationRecord
  include ApplicationHelper

  belongs_to :submission
  belongs_to :user

  validates :user, presence: true
  validates :annotation_text, presence: true, length: { minimum: 1, maximum: 2048 }
  validates :line_nr, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }, if: ->(attr) { attr.line_nr.present? }
end
