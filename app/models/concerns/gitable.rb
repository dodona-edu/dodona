module Gitable
  extend ActiveSupport::Concern

  def full_path
    raise NotImplementedError
  end

  def pull
    _out, error, status = Open3.capture3('git pull -f', chdir: full_path)
    [status.success?, error]
  end

  def clone_repo
    cmd = ['git', 'clone', remote.shellescape, full_path]
    _out, error, status = Open3.capture3(*cmd)
    unless status.success?
      errors.add(:base, "cloning failed: #{error}")
      throw :abort
    end
  end

  def repo_is_accessible
    cmd = ['git', 'ls-remote', remote.shellescape]
    _out, error, status = Open3.capture3(*cmd)
    errors.add(:remote, error) unless status.success?
  end
end
