module CoursesHelper
  def registration_action_for(**args)
    course = args[:course]
    raise 'Course must be given' unless course

    secret = args[:secret]
    membership = args[:membership]
    css_class = args[:class] || 'btn btn-filled'

    if membership.nil? || membership.unsubscribed?
      if course.open_for_user?(current_user) || current_user.nil?
        if course.moderated
          link_to t('courses.show.request_registration'),
                  subscribe_course_path(@course, secret: secret),
                  title: t('courses.registration.registration-tooltip'),
                  method: :post,
                  class: css_class
        else
          link_to t('courses.show.subscribe'),
                  subscribe_course_path(@course, secret: secret),
                  title: t('courses.registration.registration-tooltip'),
                  method: :post,
                  class: css_class
        end
      else
        tag.p t("courses.show.registration-#{@course.registration}-info", institution: @course.institution&.name)
      end
    elsif membership.pending?
      link_to t('courses.registration.remove_from_pending'),
              unsubscribe_course_path(@course),
              method: :post,
              class: 'btn btn-text'
    else
      tag.p t('courses.registration.already_a_member')
    end
  end

  def visibility_icons_for(course)
    icons = []
    if course.closed? || course.moderated
      title = []
      title.push t("courses.show.registration-#{course.registration}-info", institution: course.institution&.name) if course.hidden?
      title.push t('courses.show.moderated-info') if course.moderated
      icons.push tag.i class: 'mdi mdi-account-remove-outline', title: title.join("\n")
    end
    icons.push tag.i class: 'mdi mdi-eye-off-outline', title: t("courses.show.visibility-#{course.visibility}-info", institution: course.institution&.name) if course.hidden?
    icons.join(' ').html_safe
  end
end
