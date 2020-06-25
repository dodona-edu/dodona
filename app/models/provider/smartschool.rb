class Provider::Smartschool < Provider
  validates :identifier, uniqueness: { case_sensitive: false }, presence: true

  validates :certificate, :entity_id, :sso_url, :slo_url, absence: true

  def self.sym
    :smartschool
  end
end
