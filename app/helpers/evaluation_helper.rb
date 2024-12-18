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

  def feedback_title(feedback)
    submission_status_text = if feedback.submission.blank?
                               t 'evaluations.feedback_status.no_submission'
                             else
                               Submission.human_enum_name(:status, feedback.submission.status)
                             end

    if feedback.completed?
      t 'evaluations.feedback_status.feedback_finished', status: submission_status_text
    else
      t 'evaluations.feedback_status.feedback_unstarted', status: submission_status_text
    end
  end
end
