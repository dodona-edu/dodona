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
    @pythia = create :judge, :git_stubbed, name: 'pythia'
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_exercises
    @echo = @repository.exercises.first
  end

  def teardown
    @remote.remove
    FileUtils.rmtree @repository.full_path if File.exist?(@repository.full_path)
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
    assert_equal @pythia, @echo.judge
  end

  test 'should set exercise programming language' do
    assert_equal 'python', @echo.programming_language
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

  test 'should set exercise visibility' do
    assert_equal 'open', @echo.visibility
  end

  test 'should set exercise status' do
    assert_equal 'ok', @echo.status
  end

  test 'should push commits to remote' do
    # ensure we push to the repository
    Rails.env.stubs(:production?).returns(true)
    assert_difference('@remote.commit_count', 1) do
      File.open(@echo.config_file, 'w') do |f|
        f.write('FUCK THE SYSTEM!!1! ANARCHY!!!!')
      end
      @repository.commit 'vandalize echo config'
    end
  end
end
