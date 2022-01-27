require 'test_helper'
require 'rake'
require 'stringio'

class MergeUserTest < ActiveSupport::TestCase

  def stub_stdin(*chars)
    string_io = StringIO.new
    string_io.puts chars.join
    string_io.rewind
    $stdin = string_io
  end

  def merge_users_interactive(u1_id, u2_id)
    Rake.application.invoke_task "merge_users[#{u1_id}, #{u2_id}]"
  end

  setup do
    Rake.application.rake_require 'tasks/merge_users'
    Rake::Task.define_task(:environment)
    $stdout = File.open(File::NULL, 'w')
  end

  teardown do
    $stdin = STDIN
    $stdout = STDOUT
  end

  test 'The script should cancel on no' do
    u1 = create :user
    u2 = create :user

    stub_stdin('n')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should cancel on enter' do
    u1 = create :user
    u2 = create :user

    stub_stdin('\n')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should merge on yes' do
    u1 = create :user
    u2 = create :user

    stub_stdin('y')
    merge_users_interactive u1.id, u2.id

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should swap on swap' do
    u1 = create :user
    u2 = create :user

    stub_stdin('s', 'y')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert_not User.exists?(u2.id)
  end

  test 'The script should ignore incorrect input' do
    u1 = create :user
    u2 = create :user

    stub_stdin('a', 'z', 'd', 'y')
    merge_users_interactive u1.id, u2.id

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should fail on yes with different permissions' do
    u1 = create :user, permission: 'student'
    u2 = create :user, permission: 'zeus'

    stub_stdin('y')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should merge on force  with different permissions' do
    u1 = create :user, permission: 'student'
    u2 = create :user, permission: 'zeus'

    stub_stdin('f')
    merge_users_interactive u1.id, u2.id

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end
end
