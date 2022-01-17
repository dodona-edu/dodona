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
    _out, error, status = Open3.capture3('git fetch --all && git reset --hard $(git ls-remote -q origin HEAD | cut -f1)', chdir: full_path.to_path)
    [status.success?, error]
  end

  def create_full_path
    self.path = remote.split('/')[-1].shellescape
    # If file (or directory) already exists, append '_'
    self.path += '_' while File.exist? full_path
    full_path.mkpath
  end

  def clone_repo_delayed
    delay(queue: 'git').clone_repo
  end

  def clone_repo
    cmd = ['git', 'clone', '--depth', '1', remote.shellescape, full_path.to_path]
    _out, error, status = Open3.capture3(*cmd)
    return if status.success?

    errors.add(:base, "cloning failed: #{error}")
    throw :abort
  end

  def clone_complete?
    out, error, status = Open3.capture3('ls', chdir: full_path.to_path)
    errors.add(:remote, error) unless status.success?
    out != ''
  end

  def repo_is_accessible
    cmd = ['git', 'ls-remote', remote.shellescape]
    _out, error, status = Open3.capture3(*cmd)
    errors.add(:remote, error) unless status.success?
  end

  def github_remote?
    remote =~ %r{^(git@)|(https://)(github|gitlab)}
  end
end
