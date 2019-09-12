class ContactForm < MailForm::Base
  attribute :name, validate: true
  attribute :email, validate: Devise.email_regexp
  attribute :subject, validate: true
  attribute :message, validate: true
  attribute :dodona_user

  append :remote_ip, :user_agent

  def headers
    {
      to: Rails.application.config.dodona_email,
      subject: "Dodona contact form: #{subject}",
      from: "#{name} <#{email}>"
    }
  end
end
