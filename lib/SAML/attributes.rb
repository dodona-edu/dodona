require_relative 'settings.rb'

# Original at:
# https://github.com/apokalipto/devise_saml_authenticatable/blob/master/lib/devise_saml_authenticatable/saml_mapped_attributes.rb

module OmniAuth
  module Strategies
    class SAML
      class Attributes
        def self.resolve(raw)
          # Load the attribute map.
          mapping = YAML.load(File.read(attributes_path))

          # Parse every attribute.
          found_attributes = {}
          mapping.each_pair do |key, val|
            unless found_attributes[val]
              found_attributes[val] = raw[key] if raw[key]
            end
          end

          Hash[found_attributes]
        end

        private

        def self.attributes_path
          Rails.root.join('config', 'attribute-map.yml')
        end
      end
    end
  end
end
