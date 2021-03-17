# == Schema Information
#
# Table name: providers
#
#  id                :bigint           not null, primary key
#  type              :string(255)      default("Provider::Saml"), not null
#  institution_id    :bigint           not null
#  identifier        :string(255)
#  certificate       :text(16777215)
#  entity_id         :string(255)
#  slo_url           :string(255)
#  sso_url           :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mode              :integer          default("prefer"), not null
#  active            :boolean          default(TRUE)
#  authorization_uri :string(255)
#  client_id         :string(255)
#  issuer            :string(255)
#  jwks_uri          :string(255)
#
class Provider::Office365 < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  def self.sym
    :office365
  end

  def self.extract_institution_name(auth_hash)
    # Office 365 has no useful information, so take the domain name of the email.
    mail = auth_hash&.info&.email

    return Provider.extract_institution_name(auth_hash) unless mail =~ URI::MailTo::EMAIL_REGEXP

    domain = Mail::Address.new(mail).domain
    [domain, domain]
  end
end
