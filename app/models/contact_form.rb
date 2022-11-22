class ContactForm < MailForm::Base
  attribute :name, validate: true
  attribute :email, validate: Devise.email_regexp
  attribute :subject, validate: true
  attribute :message, validate: true
  attribute :human, validate: true
  attribute :robot, validate: true
  attribute :dodona_user

  validates :human, acceptance: true
  # robot checkbox should not be accepted
  validates :robot, inclusion: { in: %w[0] }

  def headers
    {
      to: Rails.application.config.dodona_email,
      subject: "Dodona contact form: #{subject}",
      from: "#{name} <#{email}>"
    }
  end
end
