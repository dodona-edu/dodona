# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  type           :string(255)      default("Provider::Saml"), not null
#  institution_id :bigint           not null
#  identifier     :string(255)
#  certificate    :text(65535)
#  slo_url        :string(255)
#  sso_url        :string(255)
#  saml_entity_id :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Provider::Lti < Provider
  def self.sym
    :lti
  end
end
