# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  type           :string(255)      default("Provider::Saml"), not null
#  institution_id :bigint           not null
#  identifier     :string(255)
#  certificate    :text(65535)
#  slo_url        :string(255)
#  sso_url        :string(255)
#  saml_entity_id :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Provider < ApplicationRecord
  belongs_to :institution, inverse_of: :providers

  has_many :identities, inverse_of: :provider, dependent: :destroy

  PROVIDERS = [Provider::GSuite, Provider::Office365, Provider::Saml, Provider::Smartschool].freeze

  def self.for_sym(sym)
    match = PROVIDERS.select { |prov| prov.sym == sym }.first
    return match if match.present?

    raise 'Unknown provider type.'
  end
end
