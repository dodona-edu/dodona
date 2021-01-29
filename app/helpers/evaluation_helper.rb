require 'csv'

module EvaluationHelper
  include ActionView::Helpers::NumberHelper

  def format_score(score, lang = nil)
    number_with_precision(score, precision: 2, strip_insignificant_zeros: true, locale: lang)
  end

  def scores_to_csv(evaluation)
    sheet = evaluation.evaluation_sheet
    CSV.generate do |csv|
      headers = %w[Name Email]
      headers += sheet[:evaluation_exercises].flat_map { |e| ["#{e.exercise.name} Score", "#{e.exercise.name} Max"] }
      csv << headers
      evaluation.users.order(last_name: :asc, first_name: :asc).each do |user|
        row = [user.full_name, user.email]
        feedback_l = sheet[:feedbacks][user.id]
        row += feedback_l.flat_map { |f| [f.score, f.maximum_score] }
        csv << row
      end
    end
  end
end
