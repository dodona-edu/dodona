module JwksHelper
  KEYS_LOCATION = Rails.root.join('test/files/keys').freeze

  def encode_jwt(payload, kid = nil)
    key = JWT::JWK.create_from(OpenSSL::PKey::RSA.new(File.read(JwksHelper.private_key_path)))
    payload = payload.as_json
    headers = { kid: kid || key.kid, typ: 'JWT' }
    JWT.encode(payload, key.keypair, 'RS256', headers)
  end

  def decode_jwt(payload)
    key = JWT::JWK.create_from(OpenSSL::PKey::RSA.new(File.read(JwksHelper.public_key_path)))
    payload = payload.as_json
    JWT.decode(payload, key.keypair, false, algorithm: 'RS256').first
  end

  def self.jwks_content(kid = nil)
    pk = OpenSSL::PKey::RSA.new(File.read(public_key_path))
    options = { use: 'sig' }
    options[:kid] = kid if kid
    { keys: [JWT::JWK.create_from(pk).export.merge(options)] }.to_json
  end

  def self.public_key_path
    KEYS_LOCATION.join('public_key.pem')
  end

  def self.private_key_path
    KEYS_LOCATION.join('private_key.pem')
  end
end
