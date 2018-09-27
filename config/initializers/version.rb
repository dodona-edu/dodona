module Dodona
  class Application
    module Version
      MAJOR = 2
      MINOR = 4
      PATCH = 11

      STRING = [MAJOR, MINOR, PATCH].compact.join('.')
    end
    VERSION = Version::STRING

    MIN_SUPPORTED_CLIENT = '0.0.1'.freeze
  end
end
