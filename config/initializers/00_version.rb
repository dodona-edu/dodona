module Dodona
  class Application
    module Version
      MAJOR = 5
      MINOR = 6
      PATCH = 5

      STRING = [MAJOR, MINOR, PATCH].compact.join('.')
    end
    VERSION = Version::STRING

    MIN_SUPPORTED_CLIENT = '0.0.1'.freeze
  end
end
