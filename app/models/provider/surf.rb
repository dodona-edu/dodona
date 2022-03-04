class Provider::Surf < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  def self.sym
    :surf
  end

  def self.extract_institution_name(auth_hash)
    institution_hostname = auth_hash&.info&.institution
    # Take the first part of the hostname as institution name
    school_name = institution_hostname.split('.')[0]
    [school_name, school_name]
  end
end
