class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.dodona_email
  layout 'mailer'
end
