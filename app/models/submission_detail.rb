# == Schema Information
#
# Table name: submission_details
#
#  id     :integer          not null, primary key
#  code   :text(65535)
#  result :binary(16777215)
#

class SubmissionDetail < ApplicationRecord
  belongs_to :submission, dependent: :delete, autosave: true, foreign_key: 'id'

  def result=(result)
    self[:result] = ActiveSupport::Gzip.compress(result)
  end

  def result
    ActiveSupport::Gzip.decompress(self[:result])
  end
end
