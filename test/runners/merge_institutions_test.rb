require 'test_helper'
require 'stringio'
require 'merge_users'

class MergeInstitutionsTest < ActiveSupport::TestCase
  FILE_LOCATION = Rails.root.join('test/files/output.json')

  def stub_stdin(*chars)
    string_io = StringIO.new
    chars.each { |c| string_io.print c }
    string_io.rewind
    string_io
  end

  def merge_institutions_interactive(i1_id, i2_id, *chars)
    input = stub_stdin(*chars)
    output = File.open(File::NULL, 'w')
    MergeInstitutions.new(input, output).merge_institutions_interactive(i1_id, i2_id)
  end

  test 'The script should cancel on no' do
    i1 = create :institution
    i2 = create :institution

    merge_institutions_interactive i1.id, i2.id, 'n'

    assert Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
  end

  test 'The script should cancel on enter' do
    i1 = create :institution
    i2 = create :institution

    merge_institutions_interactive i1.id, i2.id, '\n'

    assert Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
  end

  test 'The script should merge on yes' do
    i1 = create :institution
    i2 = create :institution

    merge_institutions_interactive i1.id, i2.id, 'y'

    assert_not Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
  end

  test 'The script should swap on swap' do
    i1 = create :institution
    i2 = create :institution

    merge_institutions_interactive i1.id, i2.id, 's', 'y'

    assert Institution.exists?(i1.id)
    assert_not Institution.exists?(i2.id)
  end

  test 'The script should ignore incorrect input' do
    i1 = create :institution
    i2 = create :institution

    merge_institutions_interactive i1.id, i2.id, 'a', 'z', 'd', 'y'

    assert_not Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
  end

  test 'The script should ask confirmation on overlapping usernames' do
    i1 = create :institution
    i2 = create :institution
    u1 = create :user, username: 'test', institution: i1
    u2 = create :user, username: 'test', institution: i2

    merge_institutions_interactive i1.id, i2.id, 'y', 'n'

    assert Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should ignore non overlapping usernames' do
    i1 = create :institution
    i2 = create :institution
    u1 = create :user, username: 'test', institution: i1
    u2 = create :user, username: 'test2', institution: i2

    merge_institutions_interactive i1.id, i2.id, 'y'

    assert_not Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
    u1.reload
    assert_equal i2, u1.institution
  end

  test 'The script should merge each overlapping username after confirmation' do
    i1 = create :institution
    i2 = create :institution
    overlapping_users_i1 = (1..5).map { |i| create :user, username: "test#{i}", institution: i1 }
    overlapping_users_i2 = (1..5).map { |i| create :user, username: "test#{i}", institution: i2 }
    unique_users_i1 = (1..5).map { |i| create :user, username: "foo#{i}", institution: i1 }
    unique_users_i2 = (1..5).map { |i| create :user, username: "bar#{i}", institution: i2 }

    merge_institutions_interactive i1.id, i2.id, 'y', 'y', 'y', 'y', 'y', 'y', 'y'

    assert_not Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    overlapping_users_i1.each { |u| assert_not User.exists?(u.id) }
    (overlapping_users_i2 + unique_users_i1 + unique_users_i2).each do |u|
      assert User.exists?(u.id)
      u.reload
      assert_equal i2, u.institution
      u.max_one_institution
      assert_equal 0, u.errors.count
    end
  end

  test 'The script should rollback all changes if one user merge is declined' do
    i1 = create :institution
    i2 = create :institution
    overlapping_users_i1 = (1..5).map { |i| create :user, username: "test#{i}", institution: i1 }
    overlapping_users_i2 = (1..5).map { |i| create :user, username: "test#{i}", institution: i2 }
    unique_users_i1 = (1..5).map { |i| create :user, username: "foo#{i}", institution: i1 }
    unique_users_i2 = (1..5).map { |i| create :user, username: "bar#{i}", institution: i2 }

    merge_institutions_interactive i1.id, i2.id, 'y', 'y', 'y', 'y', 'n', 'y', 'y'

    assert Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    (overlapping_users_i1 + unique_users_i1).each do |u|
      assert User.exists?(u.id)
      u.reload
      assert_equal i1, u.institution
      u.max_one_institution
      assert_equal 0, u.errors.count
    end
    (overlapping_users_i2 + unique_users_i2).each do |u|
      assert User.exists?(u.id)
      u.reload
      assert_equal i2, u.institution
      u.max_one_institution
      assert_equal 0, u.errors.count
    end
  end

  test 'The script should rollback all changes if one user merge has failed' do
    i1 = create :institution
    i2 = create :institution
    overlapping_users_i1 = (1..5).map { |i| create :user, username: "test#{i}", institution: i1, permission: 'student' }
    overlapping_users_i2 = (1..5).map { |i| create :user, username: "test#{i}", institution: i2, permission: i == 4 ? 'staff' : 'student' }
    unique_users_i1 = (1..5).map { |i| create :user, username: "foo#{i}", institution: i1 }
    unique_users_i2 = (1..5).map { |i| create :user, username: "bar#{i}", institution: i2 }

    merge_institutions_interactive i1.id, i2.id, 'y', 'y', 'y', 'y', 'y', 'y', 'y'

    assert Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    (overlapping_users_i1 + unique_users_i1).each do |u|
      assert User.exists?(u.id)
      u.reload
      assert_equal i1, u.institution
      u.max_one_institution
      assert_equal 0, u.errors.count
    end
    (overlapping_users_i2 + unique_users_i2).each do |u|
      assert User.exists?(u.id)
      u.reload
      assert_equal i2, u.institution
      u.max_one_institution
      assert_equal 0, u.errors.count
    end
  end

  test 'Swapped users are still placed in the correct institution' do
    i1 = create :institution
    i2 = create :institution
    u1 = create :user, username: 'test', institution: i1
    u2 = create :user, username: 'test', institution: i2

    merge_institutions_interactive i1.id, i2.id, 'y', 'y', 's', 'y'

    assert_not Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    assert User.exists?(u1.id)
    assert_not User.exists?(u2.id)
    u1.reload
    assert_equal i2, u1.institution
  end

  test 'The script should rollback all changes if institution merge failed' do
    i1 = create :institution
    i2 = create :institution
    create :provider, institution: i1
    create :provider, institution: i1, mode: 'link'
    overlapping_users_i1 = (1..5).map { |i| create :user, username: "test#{i}", institution: i1 }
    overlapping_users_i2 = (1..5).map { |i| create :user, username: "test#{i}", institution: i2 }
    unique_users_i1 = (1..5).map { |i| create :user, username: "foo#{i}", institution: i1 }
    unique_users_i2 = (1..5).map { |i| create :user, username: "bar#{i}", institution: i2 }

    merge_institutions_interactive i1.id, i2.id, 'y', 'y', 'y', 'y', 'y', 'y', 'y'

    assert Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    (overlapping_users_i1 + unique_users_i1).each do |u|
      assert User.exists?(u.id)
      u.reload
      assert_equal i1, u.institution
      u.max_one_institution
      assert_equal 0, u.errors.count
    end
    (overlapping_users_i2 + unique_users_i2).each do |u|
      assert User.exists?(u.id)
      u.reload
      assert_equal i2, u.institution
      u.max_one_institution
      assert_equal 0, u.errors.count
    end
  end

  test 'The script should also rollback filesystem changes' do
    i1 = create :institution
    i2 = create :institution
    u1 = create :user, username: 'test', institution: i1
    create :user, username: 'test', institution: i2
    create :user, username: 'test1', institution: i1
    create :user, username: 'test1', institution: i2

    s = create :correct_submission, user: u1, code: "print(input())\n", result: FILE_LOCATION.read
    assert s.on_filesystem?

    merge_institutions_interactive i1.id, i2.id, 'y', 'y', 'y', 'n'

    assert Institution.exists?(i1.id)
    assert Institution.exists?(i2.id)
    assert s.on_filesystem?
  end
end
