# == Schema Information
#
# Table name: posts
#
#  id         :bigint(8)        not null, primary key
#  release    :date             not null
#  draft      :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  title_en   :string(255)      not null
#  title_nl   :string(255)      not null
#

class Post < ApplicationRecord
  has_rich_text :content_en
  has_rich_text :content_nl

  default_scope { order(release: :desc) }

  def content
    if I18n.locale == :nl
      content_nl
    else
      content_en
    end
  end

  def first_paragraph
    paragraphs = content.to_plain_text&.split '\n' || []
    paragraphs.reject(&:empty?).first
  end

  def first_image
    content.embeds.first
  end

  def title
    if I18n.locale == :nl
      title_nl
    else
      title_en
    end
  end
end
