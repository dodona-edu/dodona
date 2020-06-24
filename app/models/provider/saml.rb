class Provider::Saml < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, presence: true

  def self.sym
    :saml
  end
end
