class ProgrammingLanguage < ApplicationRecord
  before_save :fill_fields

  has_many :exercises

  def fill_fields
    self.markdown_name ||= name
    self.editor_name ||= name
    self.extension ||= 'txt'
  end
end
