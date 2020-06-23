Rails.application.config.to_prepare do
  Devise::SamlSessionsController.class_eval do
    def after_sign_out_path_for(_)
      idp_entity_id = get_idp_entity_id(params)

      if idp_entity_id.present?
        request = OneLogin::RubySaml::Logoutrequest.new
        request.create(saml_config(idp_entity_id))
      else
        root_path
      end
    end
  end
end
