require 'json' # JSON support require 'fileutils'    # file system utilities
require 'securerandom' # random string generators (supports URL safety)
require 'tmpdir' # temporary file support
require 'docker' # docker client
require 'timeout' # to kill the docker after a certain time
require 'pathname' # better than File

# Handles the execution of submissions
class SubmissionRunner
  DEFAULT_CONFIG_PATH = Rails.root.join('app/runners/config.json').freeze

  def self.default_config
    JSON.parse(File.read(DEFAULT_CONFIG_PATH))
  end

  def initialize(submission)
    # definition of submission
    @submission = submission

    # derive exercise and judge definitions from submission
    @exercise = submission.exercise
    @judge = @exercise.judge

    # create name for hidden directory in docker container
    @mountsrc = nil # created when running
    @mountdst = Pathname.new('/mnt')
    @hidden_path = SecureRandom.urlsafe_base64

    # submission configuration (JSON)
    @config = compose_config

    @mac = RUBY_PLATFORM.include?('darwin')
  end

  def compose_config
    # set default configuration
    config = self.class.default_config

    # update with judge configuration
    config.deep_merge!(@judge.config)

    # update with exercise configuration
    config.deep_merge!(@exercise.merged_config['evaluation'] || {})

    # update with submission-specific configuration
    config.deep_merge!('programming_language' => @submission.exercise.programming_language&.name,
                       'natural_language' => @submission.user.lang)

    # update with links to resources in docker container needed for processing submission
    config.deep_merge!('resources' => @mountdst.join(@hidden_path, 'resources').to_path,
                       'source' => @mountdst.join(@hidden_path, 'submission', 'source').to_path,
                       'judge' => @mountdst.join(@hidden_path, 'judge').to_path,
                       'workdir' => '/home/runner/workdir')

    config
  end

  def copy_or_create(from, to)
    if from.directory?
      FileUtils.cp_r(from, to)
    else
      to.mkdir
    end
  end

  def prepare
    # set the submission's status
    @submission.status = 'running'
    @submission.save

    # create path on file system used as temporary working directory for processing the submission
    @mountsrc = Pathname.new Dir.mktmpdir(nil, @mac ? '/tmp' : nil)

    # put submission in the submission dir
    @mountsrc.join(@hidden_path).mkdir
    @mountsrc.join(@hidden_path, 'submission').mkdir
    @mountsrc.join(@hidden_path, 'submission', 'source').open('w') do |file|
      file.write(@submission.code)
    end

    # put workdir, evaluation and judge directories in working directory
    copy_or_create(@exercise.full_path.join('workdir'), @mountsrc.join('workdir'))
    copy_or_create(@exercise.full_path.join('evaluation'), @mountsrc.join(@hidden_path, 'resources'))
    copy_or_create(@judge.full_path, @mountsrc.join(@hidden_path, 'judge'))
  end

  def execute
    # fetch execution time limit from submission configuration
    time_limit = @config['time_limit']

    # fetch execution memory limit from submission configuration
    memory_limit = @config['memory_limit']

    docker_options = {
      # TODO: move entry point to docker container definition
      Cmd: ['/main.sh',
            # judge entry point
            @mountdst.join(@hidden_path, 'judge', 'run').to_path],
      Image: @exercise.merged_config['evaluation']&.fetch('image', nil) || @judge.image,
      name: "dodona-#{@submission.id}-#{random_suffix}", # assuming unique during execution
      OpenStdin: true,
      StdinOnce: true, # closes stdin after first disconnect
      NetworkDisabled: !@config['network_enabled'],
      HostConfig: {
        Memory: memory_limit,
        MemorySwap: memory_limit, # memory including swap
        # WARNING: this will cause the container to hang if /dev/sda does not exist
        BlkioDeviceWriteBps: [{ Path: '/dev/sda', Rate: 1024 * 1024 }].filter { Rails.env.production? || Rails.env.staging? },
        PidsLimit: 256,
        Binds: ["#{@mountsrc}:#{@mountdst}",
                "#{@mountsrc.join('workdir')}:#{@config['workdir']}"]
      }
    }

    # process submission in docker container
    # TODO: set user with the --user option
    # TODO: set the workdir with the -w option
    first_try = true
    begin
      container = Docker::Container.create(**docker_options)
    rescue StandardError => e
      unless first_try
        return build_error 'internal error', 'internal error', [
          build_message("Error creating docker: #{e}", 'staff', 'plain'),
          build_message(e.backtrace.join("\n"), 'staff')
        ]
      end

      first_try = false
      sleep 1
      # Create can fail due to timeouts if the worker is under heavy
      # load. Usually the container is still created, but we just
      # don't know about it in time. Make sure the old container is
      # deleted before we retry creating it to avoid name conflicts.
      begin
        Docker::Container.get(docker_options[:name]).tap do |c|
          c.stop
          c.remove
        end
      # rubocop:disable Lint/SuppressedException
      # If the container does not exist the library raises an
      # error. We can ignore this error, since we can skip the
      # previous step anyway in that case.
      rescue StandardError
      end
      # rubocop:enable Lint/SuppressedException
      # We also still change the name, because the removal can fail as well.
      docker_options[:name] = "dodona-#{@submission.id}-#{random_suffix}"
      retry
    end

    # run the container with a timeout.
    memory = 0
    before_time = Time.zone.now
    timeout_mutex = Mutex.new
    timeout = nil

    timer = Thread.new do
      while Time.zone.now - before_time < time_limit
        sleep 1
        next if Rails.env.test?
        # Check if container is still alive
        next unless Docker::Container.all.select { |c| c.id.starts_with?(container.id) || container.id.starts_with?(container.id) }.any? && container.refresh!.info['State']['Running']

        stats = container.stats
        # We check the maximum memory usage every second. This is obviously monotonic, but these stats aren't available after the container is/has stopped.
        memory = stats['memory_stats']['max_usage'] / (1024.0 * 1024.0) if stats['memory_stats']&.fetch('max_usage', nil)
      end
      timeout_mutex.synchronize do
        container.stop
        timeout = true if timeout.nil?
      end
    end

    begin
      outlines, errlines = container.tap(&:start).attach(
        stdin: StringIO.new(@config.to_json),
        stdout: true,
        stderr: true
      )
    ensure
      timeout_mutex.synchronize do
        timer.kill
        timeout = false if timeout.nil?
      end
    end

    after_time = Time.zone.now
    stdout = outlines.join.force_encoding('utf-8')
    stderr = errlines.join.force_encoding('utf-8')
    exit_status = container.wait(1)['StatusCode']
    container.delete

    # handling judge output
    if stdout.bytesize + stderr.bytesize > 10 * 1024 * 1024
      return build_error 'output limit exceeded', 'output limit exceeded', [
        build_message('Judge generated more than 10MiB of output.', 'staff', 'plain'),
        build_message("Judge exited with status code #{exit_status}.", 'staff', 'plain'),
        build_message("Standard Error #{stderr.bytesize} Bytes:", 'staff', 'plain'),
        build_message(truncate(stderr, 15_000), 'staff'),
        build_message("Standard Output #{stdout.bytesize} Bytes:", 'staff', 'plain'),
        build_message(truncate(stdout, 15_000), 'staff'),
        build_message(I18n.t('submissions.show.judge_output_too_long', locale: @submission.user.lang), 'student', 'plain')
      ]
    end

    if [0, 134, 137, 143].exclude? exit_status
      return build_error 'internal error', 'internal error', [
        build_message("Judge exited with status code #{exit_status}.", 'staff', 'plain'),
        build_message('Standard Error:', 'staff', 'plain'),
        build_message(stderr, 'staff'),
        build_message('Standard Output:', 'staff', 'plain'),
        build_message(stdout, 'staff')
      ]
    end

    result = begin
      rc = ResultConstructor.new @submission.user.lang
      rc.feed(stdout.force_encoding('utf-8'))
      rc.result(timeout)
    rescue ResultConstructorError => e
      if [134, 137, 143].include? exit_status
        description = timeout ? 'time limit exceeded' : 'memory limit exceeded'
        build_error description, description, [
          build_message("Judge exited with <strong>status code #{exit_status}.</strong>", 'staff', 'html'),
          build_message('<strong>Standard Error:</strong>', 'staff', 'html'),
          build_message(stderr, 'staff'),
          build_message('<strong>Standard Output:</strong>', 'staff', 'html'),
          build_message(stdout, 'staff')
        ]
      else
        messages = [build_message(e.title, 'staff', 'plain')]
        messages << build_message(e.description, 'staff') unless e.description.nil?
        build_error 'internal error', 'internal error', messages
      end
    end

    result[:messages] ||= []
    result[:messages] << build_message("<strong>Worker:</strong> #{`hostname`.strip}", 'zeus', 'html')
    result[:messages] << build_message(format('<strong>Runtime:</strong> %<time>.2f seconds', time: (after_time - before_time)), 'zeus', 'html')
    result[:messages] << build_message(format('<strong>Memory usage:</strong> %<memory>.2f MiB', memory: memory), 'zeus', 'html')
    result
  end

  def add_runtime_metrics(result); end

  def finalize
    return if @mountsrc.nil?

    # remove path on file system used as temporary working directory for processing the submission
    FileUtils.remove_entry_secure(@mountsrc, verbose: true)
    @mountsrc = nil
  end

  def run
    prepare
    result = execute
  rescue StandardError => e
    result = build_error 'internal error', 'internal error', [
      build_message("#{e.message}\n#{e.backtrace.inspect}", 'staff')
    ]
  ensure
    finalize
    result
  end

  private

  # ============================================================
  # json building helpers

  def build_error(status = 'internal error', description = 'internal error', messages = [])
    {
      accepted: false,
      status: status,
      description: I18n.t("activerecord.attributes.submission.statuses.#{description}", locale: @submission.user.lang),
      messages: messages
    }
  end

  def build_message(description = '', permission = 'zeus', format = 'code')
    {
      format: format,
      description: description,
      permission: permission
    }
  end

  def truncate(string, max)
    string.length > max ? "#{string[0...max]}... (truncated)" : string
  end

  def random_suffix
    SecureRandom.urlsafe_base64(10)
  end
end
