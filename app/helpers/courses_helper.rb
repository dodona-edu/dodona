module CoursesHelper
  def registration_action_for(course, secret: nil)
    case course.registration
    when 'open'
      link_to t('.subscribe'),
              subscribe_course_path(@course, secret: secret),
              method: :post,
              class: 'btn-text'
    when 'moderated'
      link_to t('.request_registration'),
              subscribe_course_path(@course, secret: secret),
              method: :post,
              class: 'btn-text'
    when 'closed'
      content_tag :p, t('.registration_closed')
    end
  end
end
