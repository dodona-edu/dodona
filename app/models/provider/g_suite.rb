class Provider::GSuite < Provider
  validates :identifier, presence: true

  def self.sym
    :google_oauth2
  end
end
