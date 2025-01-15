# == Schema Information
#
# Table name: providers
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE)
#  authorization_uri :string(255)
#  certificate       :text(16777215)
#  identifier        :string(255)
#  issuer            :string(255)
#  jwks_uri          :string(255)
#  mode              :integer          default("prefer"), not null
#  slo_url           :string(255)
#  sso_url           :string(255)
#  type              :string(255)      default("Provider::Saml"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  client_id         :string(255)
#  entity_id         :string(255)
#  institution_id    :bigint
#
class Provider::Office365 < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  def self.sym
    :office365
  end

  def self.logo
    'office365.png'
  end

  def self.readable_name
    'Office 365'
  end

  def self.extract_institution_name(auth_hash)
    # Office 365 has no useful information, so take the domain name of the email.
    mail = auth_hash&.info&.email

    return Provider.extract_institution_name(auth_hash) unless mail =~ URI::MailTo::EMAIL_REGEXP

    domain = Mail::Address.new(mail).domain
    [domain, domain]
  end

  def readable_name
    # We want to display microsoft for personal accounts
    return 'Microsoft' if institution.nil?

    super
  end

  def logo
    # We want to display microsoft for personal accounts
    return 'microsoft.png' if institution.nil?

    super
  end
end
