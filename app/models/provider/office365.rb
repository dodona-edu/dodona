class Provider::Office365 < Provider
  validates :identifier, presence: true

  def self.sym
    :office365
  end
end
