class Post < ApplicationRecord
  has_rich_text :content

  default_scope {order(release: :desc)}
end
