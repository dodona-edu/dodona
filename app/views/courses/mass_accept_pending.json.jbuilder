json.status 'ok'
json.message I18n.t('courses.show.mass_accept_notification', count: @accepted.count)
json.js render('reload_users')
