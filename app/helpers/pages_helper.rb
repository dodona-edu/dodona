module PagesHelper
  def institution_logo(logo)
    # if we use an image that doesn't exist, we get a hard error
    if File.file?("app/assets/images/idp/#{logo}")
      "idp/#{logo}"
    else
      'idp/fallback.png'
    end
  end

  def homepage_course_admin_notifications(course)
    result = []
    if course.unanswered_questions.count > 0
      result << {
        title: I18n.t('pages.course_card.unanswered-questions', count: course.unanswered_questions.count),
        link: questions_course_path(I18n.locale, course),
        icon: 'mdi-account-question colored-secondary',
        subtitle: I18n.t('pages.course_card.unanswered-questions-subtitle', count: course.unanswered_questions.count)
      }
    end

    if course.pending_members.count > 0
      result << {
        title: I18n.t('pages.course_card.pending-members', count: course.pending_members.count),
        link: course_members_path(I18n.locale, course),
        icon: 'mdi-account-clock colored-secondary',
        subtitle: I18n.t('pages.course_card.pending-members-subtitle', count: course.pending_members.count)
      }
    end

    if course.feedbacks.incomplete.count > 0
      linked_feedback = course.feedbacks.incomplete.first
      result << {
        title: I18n.t('pages.course_card.incomplete-feedbacks', count: course.feedbacks.incomplete.count),
        link: evaluation_feedback_path(I18n.locale, linked_feedback.evaluation, linked_feedback),
        icon: 'mdi-comment-multiple-outline',
        subtitle: I18n.t('pages.course_card.incomplete-feedbacks-subtitle', count: course.feedbacks.incomplete.count)
      }
    end

    result
  end
end
