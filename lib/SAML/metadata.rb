require 'uri'

require 'onelogin/ruby-saml/logging'
require 'onelogin/ruby-saml/utils'
require_relative 'settings.rb'

module OmniAuth
  module Strategies
    class SAML
      # SAML2 Metadata. XML Metadata Builder
      #
      class Metadata < OneLogin::RubySaml::Metadata
        # Overwritten to add belnet specific namespaces
        def self.add_root_element(meta_doc, settings, valid_until, cache_duration)
          namespaces = {
            "xmlns:md" => "urn:oasis:names:tc:SAML:2.0:metadata"
          }

          if settings.attribute_consuming_service.configured?
            namespaces["xmlns:saml"] = "urn:oasis:names:tc:SAML:2.0:assertion"
          end

          # added for Belnet!
          namespaces['xmlns:ds'] = 'http://www.w3.org/2000/09/xmldsig#'

          root = meta_doc.add_element("md:EntityDescriptor", namespaces)
          root.attributes["ID"] = OneLogin::RubySaml::Utils.uuid
          root.attributes["entityID"] = settings.sp_entity_id if settings.sp_entity_id
          root.attributes["validUntil"] = valid_until.strftime('%Y-%m-%dT%H:%M:%S%z') if valid_until
          root.attributes["cacheDuration"] = "PT" + cache_duration.to_s + "S" if cache_duration
          root
        end

        # Overwritten to provide belnet specific metadata
        def add_extras(root, _settings)
          org = root.add_element 'md:Organization'
          el = org.add_element 'md:OrganizationName',
                               'xml:lang' => 'en'
          el.text = 'UGent - Dodona'
          el = org.add_element 'md:OrganizationName',
                               'xml:lang' => 'nl'
          el.text = 'UGent - Dodona'
          el = org.add_element 'md:OrganizationName',
                               'xml:lang' => 'fr'
          el.text = 'UGent - Dodona'
          el = org.add_element 'md:OrganizationDisplayName',
                               'xml:lang' => 'en'
          el.text = 'UGent - Dodona'
          el = org.add_element 'md:OrganizationDisplayName',
                               'xml:lang' => 'nl'
          el.text = 'UGent - Dodona'
          el = org.add_element 'md:OrganizationDisplayName',
                               'xml:lang' => 'fr'
          el.text = 'UGent - Dodona'
          el = org.add_element 'md:OrganizationURL',
                               'xml:lang' => 'en'
          el.text = 'https://dodona.be'
          el = org.add_element 'md:OrganizationURL',
                               'xml:lang' => 'nl'
          el.text = 'https://dodona.be'
          el = org.add_element 'md:OrganizationURL',
                               'xml:lang' => 'fr'
          el.text = 'https://dodona.be'

          cp = root.add_element 'md:ContactPerson',
                                'contactType' => 'technical'
          el = cp.add_element 'md:GivenName'
          el.text = 'Dodona'
          el = cp.add_element 'md:SurName'
          el.text = 'Helpdesk'
          el = cp.add_element 'md:EmailAddress'
          el.text = 'dodona@ugent.be'
        end
      end
    end
  end
end
