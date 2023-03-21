module TimeHelper
  include ActionView::Helpers::DateHelper
  def days_ago_in_words(time)
    if time.today?
      t 'time.today'
    elsif time.yesterday?
      t 'time.yesterday'
    else
      # need to use I18n.t here because the minitest helper dos not support kwargs yet for t
      I18n.t 'time.ago', time: time_ago_in_words(time)
    end
  end
end
