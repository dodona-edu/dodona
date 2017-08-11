class ErrorMailer < ApplicationMailer
  helper :repository

  def json_error(name, email, error)
    @error = error
    @name = name
    addressee = %("#{name}" <#{email}>)
    mail to: addressee,
         subject: I18n.t(
           'error_mailer.json_error.subject',
           count: error.count,
           repository: error.repository.name
         )
  end
end
