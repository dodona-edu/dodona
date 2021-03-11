module Dodona
  class Application
    module Version
      MAJOR = 4
      MINOR = 1
      PATCH = 2

      STRING = [MAJOR, MINOR, PATCH].compact.join('.')
    end
    VERSION = Version::STRING

    MIN_SUPPORTED_CLIENT = '0.0.1'.freeze
  end
end
