module EvaluationHelper
  include ActionView::Helpers::NumberHelper

  def format_score(score, lang = nil, numeric_only = false)
    if score.nil?
      if numeric_only
        ''
      else
        '-'
      end
    else
      number_with_precision(score, precision: 2, strip_insignificant_zeros: true, locale: lang)
    end
  end
end
