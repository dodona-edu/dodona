module CoursesHelper
  def series_drawer_group(course)
    needs_series_param = !current_page?(action: 'show')
    items = course.series.map do |series|
      url = if needs_series_param
              course_path(course, series: series, anchor: series.anchor)
            else
              course_path(course, anchor: series.anchor)
            end
      [series.name.to_sym,
       {
         text: series.name,
         url: url
       }]
    end
    drawer_group title: 'Reeksen', items: items.to_h, scrollable: true
  end

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
                title: t('courses.registration.registration-tooltip'),
                method: :post,
                class: 'btn-text'
      when 'moderated'
        link_to t('courses.show.request_registration'),
                subscribe_course_path(@course, secret: secret),
                title: t('courses.registration.registration-tooltip'),
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
