require 'pathname'
require 'fileutils'

require 'concerns/gitable'
module Gitable
  # Don't delay cloning in tests
  def clone_repo_delayed
    clone_repo
  end

  def git_repository
    GitRepository.new full_path
  end
end

class GitRepository
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def git(*command)
    out, error, status = Open3.capture3('git', *command, chdir: path)
    raise error unless status.success?

    out
  end

  def commit(message)
    git 'add', '-A'
    git 'commit', '-m', message
  end

  def revert_commit
    git 'revert', 'HEAD', '--no-edit'
  end

  def remove
    FileUtils.rmtree @path
  end

  def commit_count(rev: 'HEAD')
    git('rev-list', '--count', rev).to_i
  end
end
