require 'pathname'
require 'fileutils'

module RepositoryHelper
  REMOTES_LOCATION = Rails.root.join('test', 'remotes')

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

  def initialize
    @path = Dir.mktmpdir
  end

  def init_from(path)
    git_init
    copy_dir(path)
    commit 'setup'
  end

  def commit_count(rev: 'HEAD')
    git('rev-list', '--count', rev).to_i
  end

  def update_json(rel_path, msg = nil)
    update_file(rel_path, msg) do |json|
      res = yield JSON.parse(json)
      JSON.pretty_generate(res)
    end
  end

  def update_file(rel_path, msg = nil)
    File.open(File.join(@path, rel_path), 'r+') do |f|
      contents = f.read
      f.seek(0, IO::SEEK_SET)
      f.write(yield contents)
    end
    msg ||= "update #{rel_path}"
    commit msg
  end

  def copy_dir(src_path)
    FileUtils.cp_r Dir[src_path + '/*'], @path
  end

  def git_init
    git 'init'
    git 'config', '--local', 'receive.denyCurrentBranch', 'updateInstead'
  end

  def commit(message)
    git 'add', '-A'
    git 'commit', '-m', message
  end

  def git(*command)
    out, error, status = Open3.capture3('git', *command, chdir: @path)
    raise error unless status.success?
    out
  end

  def remove
    FileUtils.rmtree @path
  end
end
