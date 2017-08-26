module CoursesHelper
  def registration_action_for(**args)
    course = args[:course]
    raise 'Course must be given' unless course

    secret = args[:secret]
    membership = args[:membership]

    if membership.nil? || membership.unsubscribed?
      case course.registration
      when 'open'
        link_to t('courses.show.subscribe'),
                subscribe_course_path(@course, secret: secret),
                method: :post,
                class: 'btn-text'
      when 'moderated'
        link_to t('courses.show.request_registration'),
                subscribe_course_path(@course, secret: secret),
                method: :post,
                class: 'btn-text'
      when 'closed'
        content_tag :p, t('courses.registration.registration_closed')
      end
    elsif membership.pending?
      content_tag :p, t('courses.registration.pending')
    else
      content_tag :p, t('courses.registration.already_a_member')
    end
  end
end
