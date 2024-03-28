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
    preferred = create :provider, institution: @institution
    create_list :provider, 2, institution: @institution, mode: :redirect

    assert_equal preferred, @institution.preferred_provider
  end

  test 'generated name is unmarked if name is updated' do
    assert_predicate @institution, :generated_name?

    @institution.update(logo: 'blabla')

    assert_predicate @institution, :generated_name?

    @institution.update(name: 'Hallo')

    assert_not @institution.generated_name?
  end

  test 'merge should remove institution' do
    institution_to_merge = create :institution
    institution_to_merge.merge_into(@institution)

    assert_predicate institution_to_merge, :destroyed?
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
    provider = create :provider, institution: institution_to_merge, mode: :prefer
    provider2 = create :provider, institution: institution_to_merge, mode: :secondary
    provider3 = create :provider, institution: institution_to_merge, mode: :redirect
    create :provider, institution: @institution, mode: :prefer

    assert institution_to_merge.merge_into(@institution)
    [provider, provider2, provider3].each do |p|
      p.reload

      assert_equal @institution, p.institution
    end
    assert_predicate provider, :secondary?
    assert_predicate provider2, :secondary?
    assert_predicate provider3, :redirect?
  end

  test 'should merge if there are smartschool users with no email' do
    institution_to_merge = create :institution
    provider = create :smartschool_provider, institution: institution_to_merge, mode: :prefer
    user = create :user, email: nil, institution: institution_to_merge
    create :identity, provider: provider, user: user
    institution = create :institution
    create :provider, institution: institution, mode: :prefer
    institution_to_merge.merge_into(institution)

    assert_predicate institution_to_merge, :destroyed?
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
    provider = create :provider, institution: institution_to_merge, mode: :prefer
    provider2 = create :provider, institution: institution_to_merge, mode: :link
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

  test 'Unique users should not be counted in similarity' do
    i1 = create :institution
    i2 = create :institution
    create :user, institution: i1, username: 'Unique', email: 'unique@b.com'
    create :user, institution: i1, username: 'Random', email: 'random@b.com'
    create :user, institution: i2, username: 'Other', email: 'other@c.com'
    create :user, institution: i2, username: 'Test', email: 'test@c.com'

    assert_equal 0, i1.similarity(i2)
  end

  test 'Overlapping usernames should be counted in similarity score' do
    i1 = create :institution
    i2 = create :institution

    create :user, institution: i1, username: 'Foo', email: 'foo@b.com'
    create :user, institution: i2, username: 'Foo', email: 'foo@c.com'

    assert_equal 1, i1.similarity(i2)

    # username similarity is case insensitive
    create :user, institution: i1, username: 'BaR', email: 'bar@b.com'
    create :user, institution: i2, username: 'bar', email: 'bar@c.com'

    assert_equal 2, i1.similarity(i2)
  end

  test 'Overlapping emails should be counted in similarity score' do
    i1 = create :institution
    i2 = create :institution

    create :user, institution: i1, email: 'foo@bar.com'
    create :user, institution: i2, email: 'foo@bar.com'

    assert_equal 1, i1.similarity(i2)

    # email similarity is case insensitive
    create :user, institution: i1, email: 'BaR@foo.com'
    create :user, institution: i2, email: 'bar@foo.com'

    assert_equal 2, i1.similarity(i2)
  end

  test ' Overlapping email domains should be counted in similarity if at least two' do
    i1 = create :institution
    i2 = create :institution

    create :user, institution: i1, email: 'a@foo.com'
    create :user, institution: i2, email: 'b@foo.com'
    create :user, institution: i2, email: 'c@foo.com'

    assert_equal 0, i1.similarity(i2)

    create :user, institution: i1, email: 'd@foo.com'
    create :user, institution: i1, email: 'e@foo.com'

    assert_equal 2, i1.similarity(i2)

    create :user, institution: i1, email: 'f@foo.com'
    create :user, institution: i2, email: 'g@foo.com'

    assert_equal 3, i1.similarity(i2)
  end

  test 'Max overlapping domain should be used in similarity score' do
    i1 = create :institution
    i2 = create :institution

    create :user, institution: i1, email: 'a@foo.com'
    create :user, institution: i1, email: 'd@foo.com'
    create :user, institution: i1, email: 'e@foo.com'
    create :user, institution: i1, email: 'f@foo.com'
    create :user, institution: i2, email: 'b@foo.com'
    create :user, institution: i2, email: 'c@foo.com'
    create :user, institution: i2, email: 'g@foo.com'

    create :user, institution: i1, email: 'e@bar.com'
    create :user, institution: i1, email: 'f@bar.com'
    create :user, institution: i2, email: 'b@bar.com'
    create :user, institution: i2, email: 'c@bar.com'

    assert_equal 3, i1.similarity(i2)
  end

  test 'Combined similarity score should account for username, domain and email' do
    i1 = create :institution
    i2 = create :institution

    create :user, institution: i1, username: 'a', email: 'a@foo.com'
    create :user, institution: i1, username: 'b', email: 'b@foo.com'
    create :user, institution: i1, username: 'c', email: 'c@foo.com'
    create :user, institution: i1, username: 'd', email: 'd@foo.com'
    create :user, institution: i1, username: 'e', email: 'e@bar.com'
    create :user, institution: i1, username: 'f', email: 'f@bar.com'

    create :user, institution: i2, username: 'a', email: 'a@foo.com' # full overlap
    create :user, institution: i2, username: 'b', email: 'b-2@foo.com' # username overlap and domain overlap
    create :user, institution: i2, username: 'g', email: 'g@foo.com' # domain overlap
    create :user, institution: i2, username: 'e', email: 'e@bar.com' # username overlap and email overlap
    create :user, institution: i2, username: 'f-2', email: 'f@bar.com' # email overlap

    assert_equal 9, i1.similarity(i2)
  end

  test 'Most similar institutions should be returned' do
    i1 = create :institution
    i2 = create :institution
    i3 = create :institution
    create :institution

    create :user, institution: i1, username: 'a', email: 'a@foo.com'
    create :user, institution: i1, username: 'b', email: 'b@foo.com'
    create :user, institution: i2, username: 'a', email: 'a@foo.com'
    create :user, institution: i2, username: 'c', email: 'c@foo.com'
    create :user, institution: i3, username: 'a', email: 'a@bar.com'
    create :user, institution: i3, username: 'c', email: 'c@bar.com'

    assert_equal 4, i1.similarity(i2)
    assert_equal 1, i1.similarity(i3)
    assert_equal 4, i2.similarity(i1)
    assert_equal 2, i2.similarity(i3)
    assert_equal 1, i3.similarity(i1)
    assert_equal 2, i3.similarity(i2)

    assert_equal ({ score: 4, id: i2.id, name: i2.name }), i1.most_similar_institution
    assert_equal ({ score: 4, id: i1.id, name: i1.name }), i2.most_similar_institution
    assert_equal ({ score: 2, id: i2.id, name: i2.name }), i3.most_similar_institution

    assert_equal i2, Institution.order_by_similarity_to(i1.id, 'DESC').first
    assert_equal i3, Institution.order_by_similarity_to(i1.id, 'DESC').second
    assert_equal i1, Institution.order_by_similarity_to(i2.id, 'DESC').first
    assert_equal i3, Institution.order_by_similarity_to(i2.id, 'DESC').second
    assert_equal i2, Institution.order_by_similarity_to(i3.id, 'DESC').first
    assert_equal i1, Institution.order_by_similarity_to(i3.id, 'DESC').second

    assert_includes [i2, i1], Institution.order_by_most_similar('DESC').first
    assert_includes [i2, i1], Institution.order_by_most_similar('DESC').second
    assert_equal i3, Institution.order_by_most_similar('DESC').third

    assert_includes [i2, i1], Institution.order_by_most_similar('ASC').last
    assert_equal i2, Institution.order_by_similarity_to(i1.id, 'ASC').last
    assert_equal i1, Institution.order_by_similarity_to(i2.id, 'ASC').last
    assert_equal i2, Institution.order_by_similarity_to(i3.id, 'ASC').last
  end
end
