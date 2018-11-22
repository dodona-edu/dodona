# == Schema Information
#
# Table name: posts
#
#  id         :bigint(8)        not null, primary key
#  title      :string(255)      not null
#  release    :date             not null
#  draft      :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Post < ApplicationRecord
  has_rich_text :content_en
  has_rich_text :content_nl

  default_scope {order(release: :desc)}
end
