class Provider::Smartschool < Provider
  validates :identifier, presence: true

  def self.sym
    :smartschool
  end
end
