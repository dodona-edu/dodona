# == Schema Information
#
# Table name: providers
#
#  id                :bigint           not null, primary key
#  type              :string(255)      default("Provider::Saml"), not null
#  institution_id    :bigint
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
class Provider::Smartschool < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  def self.sym
    :smartschool
  end

  def self.logo
    'smartschool.png'
  end

  def self.readable_name
    'Smartschool'
  end

  SMARTSCHOOL_SUFFIX = '.smartschool.be'.freeze

  def self.extract_institution_name(auth_hash)
    institution = auth_hash&.info&.institution

    # Sanity check
    return Provider.extract_institution_name(auth_hash) unless institution =~ URI::DEFAULT_PARSER.make_regexp

    uri = URI.parse(institution)
    host = uri.host
    return Provider.extract_institution_name(auth_hash) unless host.end_with?(SMARTSCHOOL_SUFFIX)

    school_name = host.delete_suffix SMARTSCHOOL_SUFFIX
    [school_name, school_name]
  end
end
