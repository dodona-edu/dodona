json.status 'ok'
json.message I18n.t('courses.show.mass_decline_notification', count: @declined.count)
json.js render('reload_users')
