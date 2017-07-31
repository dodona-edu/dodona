require 'pathname'
require 'fileutils'

module RepositoryHelper
  REMOTES_LOCATION = Rails.root.join('test', 'remotes')

  def with_local_remote(name)
    repo = local_remote(name)
    res = yield repo
    repo.remove
    res
  end

  def local_remote(name)
    mk_temp_repository File.join(REMOTES_LOCATION, name)
  end

  def mk_temp_repository(path)
    repo = TempRepository.new
    repo.init_from(path.to_s)
    repo
  end
end

class TempRepository
  attr_reader :path

  def self.mirror_path(path)
    repo = TempRepository.new
    repo.init_from(path)
    repo
  end

  def initialize
    @path = Dir.mktmpdir
  end

  def init_from(path)
    git_init
    copy_dir(path)
    commit 'setup'
  end

  def copy_dir(src_path)
    FileUtils.cp_r Dir[src_path + '/*'], @path
  end

  def git_init
    git 'init'
  end

  def commit(message)
    git 'add', '-A'
    git 'commit', '-m', message
  end

  def git(*command)
    _out, error, status = Open3.capture3('git', *command, chdir: @path)
    [status.success?, error]
  end

  def remove
    FileUtils.rmtree @path
  end
end
