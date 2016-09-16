require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require 'json-schema' # json schema validation, from json-schema gem
require 'tmpdir' # temporary file support

# base class for runners that handle Dodona submissions
class SubmissionRunner
  DEFAULT_CONFIG_PATH = Rails.root.join('app/runners/config.json').freeze

  # ADT to store to recognize an error
  # 'codes' is a list of possible exit codes that could come from this error
  # 'tokens' is a list of possible substrings that could occur in the stderr of the error
  class ErrorIdentifier
    attr_reader :tokens, :codes

    def initialize(codes, tokens)
      @codes = codes
      @tokens = tokens
    end
  end

  def build_error(status = 'runtime error', description = 'runtime error', messages = [], accepted = false)
    {
      'accepted' => accepted,
      'status' => status,
      'description' => I18n.t("activerecord.attributes.submission.statuses.#{description}", locale: @submission.user.lang),
      'messages' => messages
    }
  end

  def build_message(description = '', permission = 'zeus', format = 'code')
    {
      'format' => format,
      'description' => description,
      'permission' => permission
    }
  end

  def self.inherited(cl)
    @runners ||= [SubmissionRunner]
    @runners << cl
  end

  class << self
    attr_reader :runners
  end

  # path to the default submission json schema, used to validate judge output
  def schema_path
    Rails.root.join 'public/schemas/Submission/output.json'
  end

  def initialize(submission)
    # fields to recognize and handle errors
    @error_identifiers = {}
    @error_handlers = {}

    # container receives signal 9 from host when memory limit is exceeded
    register_error('memory limit', ErrorIdentifier.new([1], ['got signal 9']), method(:handle_memory_exceeded))

    # default exit codes of the timeout command
    register_error('time limit', ErrorIdentifier.new([9, 124, 137], []), method(:handle_timeout))

    # something else
    register_error('internal error', ErrorIdentifier.new([], []), method(:handle_unknown))

    # definition of submission
    @submission = submission

    # derive exercise and judge definitions from submission
    @exercise = submission.exercise
    @judge = @exercise.judge

    # create name for hidden directory in docker container
    @hidden_path = File.join('/mnt', SecureRandom.urlsafe_base64)

    # submission configuration (JSON)
    @config = compose_config
  end

  def compose_config
    # set default configuration
    config = JSON.parse(File.read(DEFAULT_CONFIG_PATH))

    # update with judge configuration
    config.recursive_update(@judge.config)

    # update with exercise configuration
    config.recursive_update(@exercise.merged_config['evaluation'])

    # update with submission-specific configuration
    config.recursive_update('programming_language' => @submission.exercise.programming_language,
                            'natural_language' => @submission.user.lang)

    config
  end

  # registers a pair of error identifiers and error handlers with the same identifier string (name)
  def register_error(name, identifier, handler)
    @error_identifiers[name] = identifier
    @error_handlers[name] = handler
  end

  # uses the exitcode and stderr to recognize which error occured
  # returns a string identifier of the error
  def recognize_error(exitcode, stderr)
    @error_identifiers.keys.each do |key|
      # loop over all the error identifiers
      identifier = @error_identifiers[key]
      codes = identifier.codes
      tokens = identifier.tokens

      # the process's exit code must be in the error identifier's list
      next unless codes.include?(exitcode)

      # if the token list is empty, the exit code is enough
      # if not, one token must match the process's stderr
      if tokens.empty? || tokens.any? { |token| stderr.include?(token) }
        return key
      end
    end

    # this is some serious error
    'internal error'
  end

  # uses the exitcode and stderr to generate output json
  def handle_error(exitcode, stderr)
    # figure out which error occured
    error = recognize_error(exitcode, stderr)

    # fetch the correct handler
    handler = @error_handlers[error]

    # let the handler fill in the blanks
    handler.call(stderr)
  end

  # adds the specific information to an output json for timeout errors
  def handle_timeout(stderr)
    build_error 'time limit exceeded', 'time limit exceeded', [
      build_message(stderr, 'student')
    ]
  end

  # adds the specific information to an output json for memory limit errors
  def handle_memory_exceeded(stderr)
    build_error 'memory limit exceeded', 'memory limit exceeded', [
      build_message(stderr, 'student')
    ]
  end

  # adds the specific information to an output json for unknown/general errors
  def handle_unknown(stderr)
    build_error 'internal error', 'internal error', [
      build_message(stderr, 'staff')
    ]
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
end
