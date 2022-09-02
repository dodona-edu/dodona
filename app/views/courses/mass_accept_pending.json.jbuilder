json.status 'ok'
json.message I18n.t('courses.show.mass_accept_toast', count: @accepted.count)
json.js render(partial: 'reload_users', formats: :js)
