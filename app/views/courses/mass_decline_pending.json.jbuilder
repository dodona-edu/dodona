json.status 'ok'
json.message t('courses.show.mass_decline_toast', count: @declined.count)
json.js render(partial: 'reload_users', formats: :js)
