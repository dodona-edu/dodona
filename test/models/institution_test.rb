# == Schema Information
#
# Table name: institutions
#
#  id             :bigint           not null, primary key
#  name           :string(255)
#  short_name     :string(255)
#  logo           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  generated_name :boolean          default(TRUE), not null
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

  test 'generated name is unmarked if name is updated' do
    institution = create :institution
    assert institution.generated_name?

    institution.update(logo: 'blabla')
    assert institution.generated_name?

    institution.update(name: 'Hallo')
    assert_not institution.generated_name?
  end
end
