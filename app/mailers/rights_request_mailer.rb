class RightsRequestMailer < ApplicationMailer
  def approved(request)
    @request = request
    user = request.user
    I18n.with_locale(user&.lang) do
      mail to: %("#{user.full_name}" <#{user.email}>),
           cc: Rails.application.config.dodona_email,
           subject: I18n.t('rights_request_mailer.approved.subject')
    end
  end

  def rejected(request)
    @request = request
    user = request.user
    I18n.with_locale(user&.lang) do
      mail to: %("#{user.full_name}" <#{user.email}>),
           cc: Rails.application.config.dodona_email,
           subject: I18n.t('rights_request_mailer.rejected.subject')
    end
  end

  def new_request(request)
    @request = request
    mail to: Rails.application.config.dodona_email,
         subject: "[Dodona] #{request.user.full_name} vraagt om lesgeversrechten"
  end
end
