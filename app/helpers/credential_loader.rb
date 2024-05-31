# code from https://stackoverflow.com/a/72671661
# Helps to load credentials during deploy when rails is not loaded

require 'active_support/encrypted_configuration'
require 'active_support/core_ext/hash/keys'

module CredentialLoader
  def read_credentials(environment:)
    config_path = "config/credentials/#{environment}.yml.enc"
    key_path = "config/credentials/#{environment}.key"

    unless File.exist?(config_path) && File.exist?(key_path)
      config_path = 'config/credentials.yml.enc'
      key_path = 'config/master.key'
    end

    YAML.load(
      ActiveSupport::EncryptedConfiguration.new(
        config_path: config_path,
        key_path: key_path,
        env_key: environment.to_s,
        raise_if_missing_key: true
      ).read
    )
  end
end
