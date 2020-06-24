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
