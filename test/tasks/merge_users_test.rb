require 'test_helper'
require 'stringio'
require 'rake'
load './lib/tasks/merge_users.rake'

class MergeUserTest < ActiveSupport::TestCase
  def stub_stdin(*chars)
    string_io = StringIO.new
    chars.each { |c| string_io.print c }
    string_io.rewind
    string_io
  end

  def merge_users_interactive(u1_id, u2_id, *chars)
    input = stub_stdin(*chars)
    output = File.open(File::NULL, 'w')
    MergeUsers.new(input, output).merge_users_interactive(u1_id, u2_id)
  end

  test 'The script should cancel on no' do
    u1 = create :user
    u2 = create :user

    merge_users_interactive u1.id, u2.id, 'n'

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should cancel on enter' do
    u1 = create :user
    u2 = create :user

    merge_users_interactive u1.id, u2.id, '\n'

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should merge on yes' do
    u1 = create :user
    u2 = create :user

    merge_users_interactive u1.id, u2.id, 'y'

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should swap on swap' do
    u1 = create :user
    u2 = create :user

    merge_users_interactive u1.id, u2.id, 's', 'y'

    assert User.exists?(u1.id)
    assert_not User.exists?(u2.id)
  end

  test 'The script should ignore incorrect input' do
    u1 = create :user
    u2 = create :user

    merge_users_interactive u1.id, u2.id, 'a', 'z', 'd', 'y'

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should fail on yes with different permissions' do
    u1 = create :user, permission: 'student'
    u2 = create :user, permission: 'zeus'

    merge_users_interactive u1.id, u2.id, 'y'

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should merge on force  with different permissions' do
    u1 = create :user, permission: 'student'
    u2 = create :user, permission: 'zeus'

    merge_users_interactive u1.id, u2.id, 'f'

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end
end
