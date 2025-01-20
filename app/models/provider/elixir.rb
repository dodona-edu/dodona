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
# Indexes
#
#  fk_rails_ba691498dd  (institution_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id) ON DELETE => cascade
#
class Provider::Elixir < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  def self.sym
    :elixir
  end

  def self.logo
    'elixir.png'
  end

  def self.readable_name
    'ELIXIR'
  end

  def self.extract_institution_name(auth_hash)
    institution_hostname = auth_hash&.info&.institution

    return Provider.extract_institution_name(auth_hash) if institution_hostname.nil?

    # Take the first part of the hostname as institution name
    school_name = institution_hostname.split('.')[0]
    [school_name, school_name]
  end
end
