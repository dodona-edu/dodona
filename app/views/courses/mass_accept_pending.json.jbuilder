json.status 'ok'
json.message t('courses.show.mass_accept_toast', count: @accepted.count)
json.js render(partial: 'reload_users', formats: :js)
