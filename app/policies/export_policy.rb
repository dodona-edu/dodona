class ExportPolicy < ApplicationPolicy
  def personal?
    user && record.users&.length == 1 && record.users&.first == user # Current user requests download for himself
  end

  def download_submissions_from_series?
    user&.course_admin?(record.item.course) || personal?
  end

  def download_submissions_from_course?
    user&.course_admin?(record.item) || personal?
  end

  def download_submissions_from_user?
    zeus? || personal?
  end

  def start_download_from_series?
    download_submissions_from_series?
  end

  def start_download_from_course?
    download_submissions_from_course?
  end

  def start_download_from_user?
    download_submissions_from_user?
  end
end
