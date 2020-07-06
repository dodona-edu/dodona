class Provider::GSuite < Provider
  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  def self.sym
    :google_oauth2
  end
end
