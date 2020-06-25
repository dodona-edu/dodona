# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  type           :string(255)      default("Provider::Saml"), not null
#  institution_id :bigint           not null
#  identifier     :string(255)
#  certificate    :text(65535)
#  entity_id      :string(255)
#  slo_url        :string(255)
#  sso_url        :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Provider < ApplicationRecord
  PROVIDERS = [Provider::GSuite, Provider::Office365, Provider::Saml, Provider::Smartschool].freeze

  belongs_to :institution, inverse_of: :providers

  has_many :identities, inverse_of: :provider, dependent: :destroy

  scope :gsuite, -> { where(type: Provider::GSuite.name) }
  scope :office365, -> { where(type: Provider::Office365.name) }
  scope :saml, -> { where(type: Provider::Saml.name) }
  scope :smartschool, -> { where(type: Provider::Smartschool.name) }

  def self.for_sym(sym)
    sym = sym.to_sym
    match = PROVIDERS.select { |prov| prov.sym == sym }.first
    return match if match.present?

    raise 'Unknown provider type.'
  end
end
