# == Schema Information
#
# Table name: repositories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  remote     :string(255)
#  path       :string(255)
#  judge_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'
require 'fileutils'

class RepositoryTest < ActiveSupport::TestCase
  test 'factory' do
    create :repository, :git_stubbed
  end

  test 'should not be saved when remote is not valid' do
    assert_raises(ActiveRecord::RecordInvalid) do
      create :repository, remote: 'foo@bar.baz'
    end
  end
end

class EchoRepositoryTest < ActiveSupport::TestCase
  def setup
    # ensure we push to the repository
    Rails.env.stubs(:production?).returns(true)
    @python = create :judge, :git_stubbed, name: 'python'
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_activities
    @echo = @repository.exercises.first
  end

  def teardown
    @remote.remove
    @repository.git_repository.remove
  end

  test 'should clone on create' do
    assert_not @repository.path.nil?
    assert File.exist?(@repository.full_path),
           'path does not exist'
    assert File.exist?(File.join(@repository.full_path, '.git')),
           'is not a git repository'
  end

  test 'should process exercises' do
    assert_equal 1, @repository.exercises.count
  end

  test 'should set exercise judge' do
    assert_equal @python, @echo.judge
  end

  test 'should set exercise programming language' do
    assert_equal ProgrammingLanguage.find_by(name: 'python'), @echo.programming_language
  end

  test 'should set exercise name_nl' do
    assert_equal 'Weergalm', @echo.name_nl
  end

  test 'should set exercise name_en' do
    assert_equal 'Imitation', @echo.name_en
  end

  test 'should set exercise description_format' do
    assert_equal 'html', @echo.description_format
  end

  test 'should set exercise access' do
    assert_equal 'public', @echo.access
  end

  test 'should set exercise status' do
    assert_equal 'ok', @echo.status
  end

  test 'should set exercise labels' do
    assert_equal Label.all, @echo.labels
    assert_equal 3, Label.count
  end

  test 'should dedupe label arrays' do
    assert_equal 3, @echo.labels.count
  end

  test 'should not create new labels when they are already present' do
    Label.create(name: 'label4')
    @remote.update_json("#{@echo.path}/config.json") do |json|
      json['labels'] << 'label4'
      json
    end
    @repository.reset
    @repository.process_activities
    assert_equal Label.all, @echo.labels
    assert_equal 4, Label.count
  end

  test 'should push commits to remote' do
    assert_difference('@remote.commit_count', 1) do
      File.open(@echo.config_file, 'w') do |f|
        f.write('FUCK THE SYSTEM!!1! ANARCHY!!!!')
      end
      @repository.commit 'vandalize echo config'
    end
  end

  test 'should detect deleted exercise' do
    @remote.remove_dir(@echo.path)
    @remote.commit('remove exercise')
    @repository.reset
    @repository.process_activities
    assert_equal 'removed', @echo.reload.status
  end

  test 'should detect moved exercise' do
    new_dir = 'echo2'
    @remote.rename_dir(@echo.path, new_dir)
    @remote.commit('move exercise')
    @repository.reset
    @repository.process_activities
    @echo.reload
    assert_equal 'ok', @echo.status
    assert_equal new_dir, @echo.path
  end

  test 'should restore deleted exercise when reverted' do
    @remote.remove_dir(@echo.path)
    @remote.commit('remove exercise')
    @repository.reset
    @repository.process_activities
    @remote.revert_commit
    @repository.reset
    @repository.process_activities
    @echo.reload
    assert_equal 'ok', @echo.status
  end

  test 'should restore token when manually deleted' do
    @remote.remove_dir(@echo.path)
    @remote.add_sample_dir('exercises/echo')
    @repository.reset
    @repository.process_activities
    @echo.reload
    assert_equal 'ok', @echo.status
    assert_equal 'echo', @echo.path
  end

  test 'should detect moved exercise with new exercise in original path' do
    new_dir = 'echo2'
    @remote.rename_dir(@echo.path, new_dir)
    @remote.add_sample_dir('exercises/echo')
    @repository.reset
    @repository.process_activities
    @echo.reload
    assert_equal 'ok', @echo.status
    assert_equal new_dir, @echo.path
  end

  test 'should create new exercise when config without token is placed in path of removed exercise' do
    @remote.remove_dir(@echo.path)
    @remote.commit('remove exercise')
    @repository.reset
    @repository.process_activities
    @remote.add_sample_dir('exercises/echo')
    @repository.reset
    @repository.process_activities
    @echo.reload
    assert_equal 'removed', @echo.status
    assert_equal 2, Exercise.all.count
  end

  test 'should create new exercise when exercise is copied' do
    new_dir = 'echo2'
    @remote.copy_dir(@echo.path, new_dir)
    @remote.commit('copy exercise')
    @repository.reset
    @repository.process_activities
    @echo.reload
    assert_equal 'echo', @echo.path
    assert_equal 2, Exercise.all.count
  end

  test 'should create only 1 new exercise on copy + rename' do
    new_dir1 = 'echo2'
    new_dir2 = 'echo3'
    @remote.copy_dir(@echo.path, new_dir1)
    @remote.rename_dir(@echo.path, new_dir2)
    @remote.commit('copy + rename exercise')
    @repository.reset
    @repository.process_activities
    @echo.reload
    assert [new_dir1, new_dir2].include?(@echo.path)
    assert_equal 2, Exercise.all.count
  end

  test 'should copy valid token for new exercise' do
    new_dir = 'echo2'
    @remote.copy_dir(@echo.path, new_dir)
    @remote.update_json("#{new_dir}/config.json", 'add token to new exercise') do |json|
      json['internals']['token'] = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      json
    end
    @repository.reset
    @repository.process_activities
    echo2 = Exercise.find_by(path: new_dir)
    assert_equal echo2.repository_token, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  end

  test 'should write new token to config file of copied exercise' do
    new_dir = 'echo2'
    @remote.copy_dir(@echo.path, new_dir)
    @remote.commit('copy exercise')
    @repository.reset
    @repository.process_activities
    echo2 = Activity.find_by(path: new_dir)
    assert_not_equal @echo.repository_token, echo2.config['internals']['token']
  end

  test 'should overwrite memory limit that is too high' do
    @remote.update_json("#{@echo.path}/config.json", 'set a ridiculous memory limit') do |json|
      json['evaluation']['memory_limit'] = 500_000_000_000
      json
    end
    @repository.reset
    @repository.process_activities
    assert_equal 500_000_000, JSON.parse(File.read(File.join(@remote.path, @echo.path, 'config.json')))['evaluation']['memory_limit']
  end

  test 'should convert to content page' do
    assert @echo.submissions.empty?
    @remote.update_json("#{@echo.path}/config.json", 'convert to content page') do |json|
      json['type'] = 'content'
      json
    end
    @repository.reset
    @repository.process_activities
    assert @repository.activities.first.content_page?
    assert @repository.activities.first.ok?
    assert_equal 1, @repository.activities.count
  end

  test 'should move submissions to clone when converting to content page' do
    @echo.submissions << create(:submission)
    submission = @echo.submissions.first
    @remote.update_json("#{@echo.path}/config.json", 'convert to content page') do |json|
      json['type'] = 'content'
      json
    end
    @repository.reset
    @repository.process_activities
    assert_equal 2, @repository.activities.count

    original = @repository.activities.find { |a| a.id == @echo.id }
    other = @repository.activities.find { |a| a.id != @echo.id }
    submission.reload

    assert original.content_page?
    assert original.ok?
    assert other.exercise?
    assert other.removed?
    assert_equal other.id, submission.exercise_id
  end

  test 'should catch invalid dirconfig files' do
    @remote.write_file('dirconfig.json') do
      '{"invalid json",,}'
    end
    @repository.reset
    assert_raises(AggregatedConfigErrors) do
      @repository.process_activities
    end
    @echo.reload
    assert_equal 'not_valid', @echo.status
  end

  test 'should catch invalid config file' do
    @remote.write_file("#{@echo.path}/config.json") do
      '{"invalid json",,}'
    end
    @repository.reset
    assert_raises(AggregatedConfigErrors) do
      @repository.process_activities
    end
    @echo.reload
    assert_equal 'not_valid', @echo.status
  end

  test 'should catch config file that does not contain object' do
    @remote.write_file("#{@echo.path}/config.json") do
      '"json string"'
    end
    @repository.reset
    assert_raises(AggregatedConfigErrors) do
      @repository.process_activities
    end
    @echo.reload
    assert_equal 'not_valid', @echo.status
  end
end
