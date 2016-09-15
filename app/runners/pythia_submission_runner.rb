require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require 'json-schema' # json schema validation, from json-schema gem
require 'tmpdir' # temporary file support

# runner that implements the Pythia workflow of handling submissions
class PythiaSubmissionRunner < SubmissionRunner
  def schema_path
    Rails.root.join 'public/schemas/DodonaSubmission/output.json'
  end

  def initialize(submission)
    super(submission)

    # result of processing the submission (SPOJ)
    @result = nil

    # path on file system used as temporary working directory for processing the submission
    @path = nil

    @mac = RUBY_PLATFORM.include?('darwin')
  end

  # calculates the difference between the biggest and smallest values
  # in a log file
  def logged_value_range(path)
    max_logged_value(path) - min_logged_value(path)
  end

  # extracts the smallest value from a log file
  def min_logged_value(path)
    m = nil

    file = File.open(path).read

    file.each_line do |line|
      # each log line has a time stamp an actual value
      split = line.split
      value = split[1].to_i

      m = value if m.nil? || value < m
    end

    m
  end

  # extracts the biggest value from a log file
  def max_logged_value(path)
    m = -1

    file = File.open(path).read

    file.each_line do |line|
      # each log line has a time stamp and an actual value
      split = line.split
      value = split[1].to_i
      m = value if value > m
    end

    m
  end

  # extracts the last timestamp from a log file
  def last_timestamp(path)
    line = IO.readlines(path).last

    split = line.split

    split[0].to_i
  end

  def compose_config
    config = super

    # set links to resources in docker container needed for processing submission
    config.recursive_update('home' => File.join(@hidden_path, 'resources', 'judge'),
                            'source' => File.join(@hidden_path, 'submission', 'source.py'))

    config
  end

  def prepare
    # set the submission's status
    @submission.status = 'running'
    @submission.save

    # create path on file system used as temporary working directory for processing the submission
    @path = Dir.mktmpdir(nil, @mac ? '/tmp' : nil)

    # put submission in working directory (subdirectory submission)
    Dir.mkdir("#{@path}/submission/")
    open("#{@path}/submission/source.py", 'w') do |file|
      file.write(@submission.code)
    end

    # put submission resources in working directory (subdirectory resources)
    Dir.mkdir("#{@path}/resources/")
    src = File.join(@exercise.path, 'evaluation', 'media')
    if File.directory?(src)
      dest = File.join(File.join(@path, 'resources'))
      FileUtils.cp_r(src, dest)
    end

    # otherwise docker will make these as root
    # TODO: can we fix this?
    Dir.mkdir("#{@path}/submission/judge/")
    Dir.mkdir("#{@path}/submission/resources")
  end

  def execute
    # fetch execution time limit from submission configuration
    time_limit = @config['time_limit']

    # fetch execution memory limit from submission configuration
    memory_limit = @config['memory_limit']

    # mac support
    timeout_command = @mac ? 'gtimeout' : 'timeout'

    # process submission in docker container
    # TODO: set user with the --user option
    # TODO: set the workdir with the -w option
    stdout, stderr, status = Open3.capture3(
      # set timeout
      timeout_command, '-k', time_limit.to_s, time_limit.to_s,
      # start docker container
      'docker', 'run',
      # activate stdin
      '-i',
      # remove dead container
      '--rm',
      # 'memory limit', physical mapped and swap memory?
      '--memory', "#{memory_limit}B",
      # mount submission as a hidden directory
      # DONE: made read-only in entry point of docker container
      '-v', "#{@path}/submission:#{@hidden_path}/submission",
      # mount judge resources in hidden directory (read-only)
      '-v', "#{@exercise.full_path}/evaluation:#{@hidden_path}/resources/judge:ro",
      # mount judge definition in hidden directory (read-only)
      '-v', "#{@judge.full_path}:#{@hidden_path}/judge:ro",
      # create runner home directory as read/write
      '-v', "#{@path}/resources:/home/runner",
      # image used to launch docker container
      @judge.image.to_s,
      # initialization script of docker container (so-called entry point of docker container)
      # TODO: move entry point to docker container definition
      # TODO: rename this into something more meaningful (suggestion: launch_runner)
      '/main.sh',
      # $1: script that starts processing the submission in the docker container
      "#{@hidden_path}/judge/run.sh",
      # $2: hidden path
      @hidden_path.to_s,
      stdin_data: @config.to_json
    )

    # TODO, stopsig and termsig aren't real exit statuses
    exit_status = if status.exited?
                    status.exitstatus
                  elsif wait_thr.value.stopped?
                    status.stopsig
                  else
                    status.termsig
                  end

    if exit_status.nonzero?
      # error handling in class Runner
      result = handle_error(exit_status, stderr)
    else
      # submission was processed succesfully (stdout contains description of result)

      result = JSON.parse(stdout)

      if JSON::Validator.validate(schema_path.to_s, result)
        add_runtime_metrics(result)
      else
        result = build_error 'internal error', 'internal error', [
          build_message(JSON::Validator.fully_validate(schema_path.to_s, result).join("\n"), 'staff')
        ]
      end
    end

    # set result of processing the submission
    @result = result
  end

  def add_runtime_metrics(result)
    metrics = result['runtime_metrics']

    metrics = {} if metrics.nil?

    unless metrics.key?('wall_time')
      value = last_timestamp(File.join(@path, 'resources', 'user_time.logs')) / 1000.0
      metrics['wall_time'] = value

      value = logged_value_range(File.join(@path, 'resources', 'user_time.logs')) / 100.0
      metrics['user_time'] = value

      value = logged_value_range(File.join(@path, 'resources', 'system_time.logs')) / 100.0
      metrics['system_time'] = value
    end

    unless metrics.key?('peak_memory')
      value = logged_value_range(File.join(@path, 'resources', 'memory_usage.logs'))
      metrics['peak_memory'] = value

      value = logged_value_range(File.join(@path, 'resources', 'anonymous_memory.logs'))
      metrics['peak_anonymous_memory'] = value
    end

    result['runtime_metrics'] = metrics
  end

  def finalize
    # save the result
    @submission.result = @result.to_json
    @submission.status = Submission.normalize_status(@result['status'])
    @submission.accepted = @result['accepted']
    @submission.summary = @result['description']
    @submission.save

    # remove path on file system used as temporary working directory for processing the submission
    unless @path.nil?
      FileUtils.remove_entry_secure(@path, verbose: true)
      @path = nil
    end
  end

  def run
    prepare
    execute
  rescue Exception => e
    @result = build_error 'internal error', 'internal error', [
      build_message(e.message + "\n" + e.backtrace.inspect, 'staff')
    ]
  ensure
    finalize
  end
end
