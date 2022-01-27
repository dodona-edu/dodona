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
    u1 = create :user, id: 1_000_001
    u2 = create :user, id: 1_000_002

    stub_stdin('n')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should cancel on enter' do
    u1 = create :user, id: 1_000_003
    u2 = create :user, id: 1_000_004

    stub_stdin('\n')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should merge on yes' do
    u1 = create :user, id: 1_000_005
    u2 = create :user, id: 1_000_006

    stub_stdin('y')
    merge_users_interactive u1.id, u2.id

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should swap on swap' do
    u1 = create :user, id: 1_000_007
    u2 = create :user, id: 1_000_008

    stub_stdin('s', 'y')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert_not User.exists?(u2.id)
  end

  test 'The script should ignore incorrect input' do
    u1 = create :user, id: 1_000_009
    u2 = create :user, id: 1_000_010

    stub_stdin('a', 'z', 'd', 'y')
    merge_users_interactive u1.id, u2.id

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should fail on yes with different permissions' do
    u1 = create :user, permission: 'student', id: 1_000_011
    u2 = create :user, permission: 'zeus', id: 1_000_012

    stub_stdin('y')
    merge_users_interactive u1.id, u2.id

    assert User.exists?(u1.id)
    assert User.exists?(u2.id)
  end

  test 'The script should merge on force  with different permissions' do
    u1 = create :user, permission: 'student', id: 1_000_013
    u2 = create :user, permission: 'zeus', id: 1_000_014

    stub_stdin('f')
    merge_users_interactive u1.id, u2.id

    assert_not User.exists?(u1.id)
    assert User.exists?(u2.id)
  end
end
