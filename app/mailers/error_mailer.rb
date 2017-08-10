class ErrorMailer < ApplicationMailer
  def json_error(name, email, repository, error)
    @error = error
    @repository = repository
    email_with_name = %("#{name}" <#{email}>)
    mail to: email_with_name,
         subject: 'error'
  end
end
