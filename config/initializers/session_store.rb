# Be sure to restart your server when you modify this file.

if Rails.env.production? || Rails.env.staging?
  Rails.application.config.session_store :cookie_store, key: '_dodona_session', same_site: :none, secure: true
else
  Rails.application.config.session_store :cookie_store, key: '_dodona_session'
end
