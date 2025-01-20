# == Schema Information
#
# Table name: activities
#
#  id                      :integer          not null, primary key
#  access                  :integer          default("public"), not null
#  access_token            :string(16)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#  description_en_present  :boolean          default(FALSE)
#  description_format      :string(255)
#  description_nl_present  :boolean          default(FALSE)
#  draft                   :boolean          default(TRUE)
#  name_en                 :string(255)
#  name_nl                 :string(255)
#  path                    :string(255)
#  repository_token        :string(64)       not null
#  search                  :string(4096)
#  series_count            :integer          default(0), not null
#  status                  :integer          default("ok")
#  type                    :string(255)      default("Exercise"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  judge_id                :integer
#  programming_language_id :bigint
#  repository_id           :integer
#

class ContentPage < Activity
  def content_page?
    true
  end

  class << self
    def type
      'content'
    end
  end
end
