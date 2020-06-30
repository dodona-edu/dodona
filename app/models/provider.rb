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
  enum mode: { prefer: 0, redirect: 1 }

  PROVIDERS = [Provider::GSuite, Provider::Office365, Provider::Saml, Provider::Smartschool].freeze

  belongs_to :institution, inverse_of: :providers

  has_many :identities, inverse_of: :provider, dependent: :destroy

  scope :gsuite, -> { where(type: Provider::GSuite.name) }
  scope :office365, -> { where(type: Provider::Office365.name) }
  scope :saml, -> { where(type: Provider::Saml.name) }
  scope :smartschool, -> { where(type: Provider::Smartschool.name) }

  validates :mode, presence: true
  validate :at_least_one_preferred
  validate :at_most_one_preferred

  def self.for_sym(sym)
    sym = sym.to_sym
    match = PROVIDERS.select { |prov| prov.sym == sym }.first
    return match if match.present?

    raise 'Unknown provider type.'
  end

  private

  def at_least_one_preferred
    return if institution.blank?

    # Find the current preferred provider.
    preferred_provider = institution.preferred_provider

    # Already a preferred provider.
    return if preferred_provider.present?

    # Current provider is preferred.
    return if prefer?

    # Invalid.
    errors.add(:mode, 'must be preferred')
  end

  def at_most_one_preferred
    return if institution.blank?

    # Find the current preferred provider.
    preferred_provider = institution.preferred_provider

    # No preferred provider yet.
    return if preferred_provider.blank?

    # Current provider is not preferred.
    return unless prefer?

    # Current provider is the preferred provider.
    return if preferred_provider.id == id

    # Invalid.
    errors.add(:mode, 'may not be preferred')
  end
end
