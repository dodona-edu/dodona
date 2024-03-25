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
class Provider::FlemishGovernment < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }
  validates :client_id, :issuer, absence: true

  def self.sym
    :flemish_government
  end

  def self.logo
    'vlaamse-overheid.png'
  end

  def self.readable_name
    'Vlaamse Overheid'
  end

  def self.extract_institution_name(auth_hash)
    institution_name = auth_hash&.info&.institution_name

    return Provider.extract_institution_name(auth_hash) if institution_name.nil?

    [institution_name, institution_name]
  end
end
