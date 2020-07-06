# == Schema Information
#
# Table name: institutions
#
#  id          :bigint           not null, primary key
#  name        :string(255)
#  short_name  :string(255)
#  logo        :string(255)
#  sso_url     :string(255)
#  slo_url     :string(255)
#  certificate :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  entity_id   :string(255)
#  provider    :integer
#  identifier  :string(255)
#

require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase
  test 'institution factory' do
    create :institution
  end

  test 'get prefered provider' do
    institution = create :institution
    prefered = create :provider, institution: institution
    create_list :provider, 4, institution: institution, mode: :redirect

    assert prefered, institution.preferred_provider
  end
end
