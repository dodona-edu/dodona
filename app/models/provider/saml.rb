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
class Provider::Saml < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, presence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, absence: true
  validates :entity_id, uniqueness: { case_sensitive: false }

  validates :identifier, absence: true

  def identifier_string
    entity_id
  end

  def self.sym
    :saml
  end

  def self.extract_institution_name(auth_hash)
    Provider.extract_institution_name(auth_hash)
  end
end
