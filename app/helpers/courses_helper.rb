module CoursesHelper
  def registration_action_for(**args)
    course = args[:course]
    raise 'Course must be given' unless course

    secret = args[:secret]
    membership = args[:membership]

    if membership.nil? || membership.unsubscribed?
      if course.open_for_all? || (course.open_for_institution? && (course.institution == current_user&.institution || current_user.nil?))
        if course.moderated
          link_to t('courses.show.request_registration'),
                  subscribe_course_path(@course, secret: secret),
                  title: t('courses.registration.registration-tooltip'),
                  method: :post,
                  class: 'btn btn-filled'
        else
          link_to t('courses.show.subscribe'),
                  subscribe_course_path(@course, secret: secret),
                  title: t('courses.registration.registration-tooltip'),
                  method: :post,
                  class: 'btn btn-filled'
        end
      else
        tag.p t('courses.registration.registration_closed')
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
end
