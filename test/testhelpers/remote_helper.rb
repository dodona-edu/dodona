require 'pathname'
require 'fileutils'

require 'testhelpers/git_helper'

module RemoteHelper
  def local_remote(sample_dir = nil)
    repository = TempRepository.new
    repository.add_sample_dir(sample_dir) if sample_dir
    repository
  end
end
class TempRepository < GitRepository
  REMOTES_LOCATION = Rails.root.join('test/remotes')

  def initialize
    super Dir.mktmpdir
    init_git
  end

  def init_git
    git 'init'
    # allow pushing to master (current) branch
    git 'config', '--local', 'receive.denyCurrentBranch', 'updateInstead'
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

  def write_file(rel_path, msg = nil)
    File.open(File.join(@path, rel_path), 'w') do |f|
      f.write(yield)
    end
    msg ||= "create #{rel_path}"
    commit msg
  end

  def rename_dir(from_path, to_path)
    FileUtils.move(File.join(@path, from_path), File.join(@path, to_path))
  end

  def remove_dir(dir_path)
    FileUtils.remove_dir(File.join(@path, dir_path))
  end

  def copy_dir(src_path, dest_path)
    FileUtils.copy_entry(File.join(@path, src_path), File.join(@path, dest_path))
  end

  def add_dir(src_path, msg: nil)
    FileUtils.cp_r Dir[src_path + '/*'], @path
    msg ||= "add #{src_path}"
    commit msg
  end

  def add_sample_dir(src_path, msg: nil)
    msg ||= "add #{src_path}"
    add_dir File.join(REMOTES_LOCATION, src_path), msg: msg
  end
end
