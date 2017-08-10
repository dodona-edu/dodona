class ErrorMailer < ApplicationMailer
  def json_error(name, email, error)
    @error = error
    email_with_name = %("#{name}" <#{email}>)
    mail to: email_with_name,
         subject: 'error'
  end
end
