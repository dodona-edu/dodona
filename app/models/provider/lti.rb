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
class Provider::Lti < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :identifier, absence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, presence: true

  def self.sym
    :lti
  end

  def self.extract_institution_name(auth_hash)
    Provider.extract_institution_name(auth_hash)
  end
end
