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
#  category       :integer          default("secondary"), not null
#

require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase
  setup do
    @institution = institutions(:ugent)
  end

  test 'get preferred provider' do
    preferred = build :provider, institution: @institution
    build_list :provider, 2, institution: @institution, mode: :redirect

    assert preferred, @institution.preferred_provider
  end

  test 'generated name is unmarked if name is updated' do
    assert @institution.generated_name?

    @institution.update(logo: 'blabla')
    assert @institution.generated_name?

    @institution.update(name: 'Hallo')
    assert_not @institution.generated_name?
  end

  test 'merge should remove institution' do
    institution_to_merge = create :institution
    institution_to_merge.merge_into(@institution)
    assert institution_to_merge.destroyed?
  end

  test 'merge should update courses' do
    institution_to_merge = create :institution
    courses = create_list :course, 2, institution: institution_to_merge
    assert institution_to_merge.merge_into(@institution)
    courses.each do |c|
      c.reload
      assert_equal @institution, c.institution
    end
  end

  test 'merge should update providers' do
    institution_to_merge = create :institution
    provider = create(:provider, institution: institution_to_merge, mode: :prefer)
    provider2 = create(:provider, institution: institution_to_merge, mode: :secondary)
    provider3 = create(:provider, institution: institution_to_merge, mode: :redirect)
    create :provider, institution: @institution, mode: :prefer
    assert institution_to_merge.merge_into(@institution)
    [provider, provider2, provider3].each do |p|
      p.reload
      assert_equal @institution, p.institution
    end
    assert provider.secondary?
    assert provider2.secondary?
    assert provider3.redirect?
  end

  test 'should merge if there are smartschool users with no email' do
    institution_to_merge = create :institution
    provider = create(:smartschool_provider, institution: institution_to_merge, mode: :prefer)
    user = create :user, email: nil, institution: institution_to_merge
    create :identity, provider: provider, user: user
    institution = create :institution
    create :provider, institution: institution, mode: :prefer
    institution_to_merge.merge_into(institution)
    assert institution_to_merge.destroyed?
    assert_equal user.reload.institution_id, institution.id
  end

  test 'merge should update users' do
    institution_to_merge = create :institution
    users = create_list :user, 2, institution: institution_to_merge
    assert institution_to_merge.merge_into(@institution)
    users.each do |u|
      u.reload
      assert_equal @institution, u.institution
    end
  end

  test 'should not merge if there are link providers' do
    institution_to_merge = create :institution
    provider = create(:provider, institution: institution_to_merge, mode: :prefer)
    provider2 = create(:provider, institution: institution_to_merge, mode: :link)
    create :provider, institution: @institution, mode: :prefer
    assert_not institution_to_merge.merge_into(@institution)
    [provider, provider2].each do |p|
      p.reload
      # call should not have changed anything
      assert_equal institution_to_merge, p.institution
    end
  end

  test 'should not merge if there are overlapping usernames' do
    institution_to_merge = create :institution
    user = create :user, institution: institution_to_merge
    create :user, institution: @institution, username: user.username
    assert_not institution_to_merge.merge_into(@institution)
    user.reload
    assert_equal institution_to_merge, user.institution
  end
end
