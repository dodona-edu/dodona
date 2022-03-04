class Provider::Surf < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :authorization_uri, :client_id, :issuer, :jwks_uri, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  def self.sym
    :surf
  end

  def self.extract_institution_name(auth_hash)
    institution = auth_hash&.info&.institution

    # Sanity check
    return Provider.extract_institution_name(auth_hash) unless institution =~ URI::DEFAULT_PARSER.make_regexp

    uri = URI.parse(institution)
    host = uri.host
    school_name = host.split('.')[0]
    [school_name, school_name]
  end
end
