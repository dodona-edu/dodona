class Provider::Office365 < Provider
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true

  def self.sym
    :office365
  end
end
