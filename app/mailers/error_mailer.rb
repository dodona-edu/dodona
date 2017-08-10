class ErrorMailer < ApplicationMailer
  def json_error(name, email, error)
    @error = error
    addressee = %("#{name}" <#{email}>)
    mail to: addressee,
         subject: 'error'
  end
end
