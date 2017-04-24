module Gitable
  extend ActiveSupport::Concern

  def full_path
    raise NotImplementedError
  end

  def pull
    return reset unless Rails.env.production?
    _out, error, status = Open3.capture3('git pull -f', chdir: full_path.to_path)
    [status.success?, error]
  end

  def reset
    _out, error, status = Open3.capture3('git fetch --all && git reset --hard origin/master', chdir: full_path.to_path)
    [status.success?, error]
  end

  def remote_to_pathname
    remote.split('/')[-1].shellescape
  end

  def clone_repo
    self.path = remote_to_pathname
    begin
      full_path.mkdir
    rescue Errno::EEXIST
      self.path += '_'
      retry
    end
    cmd = ['git', 'clone', '--depth', '1', remote.shellescape, full_path.to_path]
    _out, error, status = Open3.capture3(*cmd)
    return if status.success?

    errors.add(:base, "cloning failed: #{error}")
    throw :abort
  end

  def repo_is_accessible
    cmd = ['git', 'ls-remote', remote.shellescape]
    _out, error, status = Open3.capture3(*cmd)
    errors.add(:remote, error) unless status.success?
  end
end
