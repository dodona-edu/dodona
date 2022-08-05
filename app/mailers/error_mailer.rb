class ErrorMailer < ApplicationMailer
  helper :repository

  def set_fields(error, user, name, email)
    @error = error
    @user = user || User.find_by(email: email)
    if @user
      @name = @user.full_name
      @email = @user.email
    else
      @name = name || ''
      @email = email
    end
  end

  def json_error(error, user: nil, name: nil, email: nil)
    set_fields(error, user, name, email)

    I18n.with_locale(@user&.lang) do
      mail to: %("#{@name}" <#{@email}>),
           cc: Rails.application.config.dodona_email,
           subject: I18n.t(
             'error_mailer.json_error.subject',
             count: error.count,
             repository: error.repository.name
           )
    end
  end

  def git_error(error, user: nil, name: nil, email: nil)
    set_fields(error, user, name, email)

    I18n.with_locale(@user&.lang) do
      mail to: %("#{@name}" <#{@email}>),
           cc: Rails.application.config.dodona_email,
           subject: I18n.t(
             'error_mailer.git_error.subject',
             repository: error.repository.name
           )
    end
  end
end
