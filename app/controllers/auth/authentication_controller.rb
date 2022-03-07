class Auth::AuthenticationController < Devise::SessionsController
  # A sign-out route is inherited from the parent controller.

  has_scope :by_institution, as: 'institution_id'

  skip_before_action :verify_authenticity_token, raise: false

  def sign_in
    @universities = [
      Provider.find_by(entity_id: 'https://identity.ugent.be/simplesaml/saml2/idp/metadata.php'),
      Provider.find_by(entity_id: 'urn:mace:kuleuven.be:kulassoc:kuleuven.be'),
      Provider.find_by(identifier: '792e08fb-2d54-4a8e-af72-202548136ef6'), # UAntwerpen
      Provider.find_by(entity_id: 'https://idp.uhasselt.be:443/idp/shibboleth'),
      Provider.find_by(identifier: '695b7ca8-2da8-4545-a2da-42d03784e585') # VUB
    ].compact
    @colleges = [
      # Provider.find_by(identifier: '33d8cf3c-2f14-48c0-9ad6-5d2825533673'), # AP
      Provider.find_by(identifier: 'b6e080ea-adb9-4c79-9303-6dcf826fb854'), # Artevelde
      # Provider.find_by(identifier: 'c2a59f2b-5d20-4b2a-a9a3-7a8605b14e3f'), # Erasmus
      Provider.find_by(entity_id: 'https://idp.hogent.be/idp'), # HoGent
      Provider.find_by(identifier: '4ded4bb1-6bff-42b3-aed7-6a36a503bf7a'), # HoWest
      # Provider.find_by(identifier: '850f9344-e078-467e-9c5e-84d82f208ac7'), # HS Leiden
      # Provider.find_by(identifier: 'ed1fc57f-8a97-47e7-9de1-9302dfd786ae'), # KdG
      Provider.find_by(identifier: '0bff66c5-45db-46ed-8b81-87959e069b90'), # PXL
      Provider.find_by(identifier: '77d33cc5-c9b4-4766-95c7-ed5b515e1cce'), # Thomas More
      Provider.find_by(identifier: 'e638861b-15d9-4de6-a65d-b48789ae1f08') # UCLL
    ].compact
    @other = [
      Provider.find_by(issuer: 'https://authenticatie.vlaanderen.be/op'),
      Provider.find_by(entity_id: 'https://login.elixir-czech.org/idp/') # Elixir
    ].compact

    # Providers that are not necessarily specific to one institution.
    @generic_providers = {
      Provider::Smartschool => { image: 'smartschool.png', name: 'Smartschool' },
      Provider::Office365 => { image: 'office365.png', name: 'Office 365' },
      Provider::GSuite => { image: 'Google-logo.png', name: 'Google Workspace' },
      Provider::Surf => { image: 'surf-logo.svg', name: 'SURFconext' }
    }

    # Calculate some information for these providers.
    @generic_providers.each do |key, value|
      value[:link] = omniauth_authorize_path(:user, key.sym)
    end

    @providers = Provider.all
    @title = I18n.t('auth.sign_in.sign_in')
    @oauth_providers = apply_scopes(@providers
      .includes(:institution)
      .where(type: @generic_providers.keys)
      .where(mode: :prefer)
      .where(institutions: { generated_name: false }))
    render 'auth/sign_in'
  end
end
