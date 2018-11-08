class Version < ApplicationRecord
  has_rich_text :notes

  default_scope {order(release: :desc)}
end
