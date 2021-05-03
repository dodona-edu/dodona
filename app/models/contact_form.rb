class ContactForm < MailForm::Base
  attribute :name, validate: true
  attribute :email, validate: Devise.email_regexp
  attribute :subject, validate: true
  attribute :message, validate: true
  attribute :dodona_user

  def headers
    {
      to: Rails.application.config.dodona_email,
      subject: "Dodona contact form: #{subject}",
      from: "#{name} <#{email}>"
    }
  end
end
