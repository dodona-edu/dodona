require 'json'        # JSON support
require 'fileutils'   # file system utilities
require 'securerandom'# random string generators (supports URL safety)
require 'json-schema' # json schema validation, from json-schema gem
require 'tmpdir'      # temporary file support
require 'docker'      # docker client
require 'timeout'     # to kill the docker after a certain time

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

    # path on file system used as temporary working directory for processing the submission
    @path = nil

    @mac = RUBY_PLATFORM.include?('darwin')
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
      build_message(stderr, 'staff')
    ]
  end

  # adds the specific information to an output json for memory limit errors
  def handle_memory_exceeded(stderr)
    build_error 'memory limit exceeded', 'memory limit exceeded', [
      build_message(stderr, 'staff')
    ]
  end

  # adds the specific information to an output json for unknown/general errors
  def handle_unknown(stderr)
    build_error 'internal error', 'internal error', [
      build_message(stderr, 'staff')
    ]
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

    # update with links to resources in docker container needed for processing submission
    config.recursive_update('resources' => File.join(@hidden_path, 'resources'),
                            'source'    => File.join(@hidden_path, 'submission', 'source'),
                            'judge'     => File.join(@hidden_path, 'judge'),
                            'workdir'   => '/home/runner/workdir')

    config
  end

  def prepare
    # set the submission's status
    @submission.status = 'running'
    @submission.save

    # create path on file system used as temporary working directory for processing the submission
    @path = Dir.mktmpdir(nil, @mac ? '/tmp' : nil)

    # put submission in the submission dir
    Dir.mkdir(File.join(@path, 'submission'))
    open(File.join(@path, 'submission', 'source'), 'w') do |file|
      file.write(@submission.code)
    end

    # put submission resources in working directory
    src = File.join(@exercise.full_path, 'workdir')
    if File.directory?(src)
      FileUtils.cp_r(src, @path)
    else
      Dir.mkdir(File.join(@path, 'workdir'))
    end

    # ensure directories exist before mounting
    begin
      Dir.mkdir(File.join(@path, 'logs'))
    rescue
      'existed'
    end
    begin
      Dir.mkdir(File.join(@exercise.full_path, 'evaluation'))
    rescue
      'existed'
    end
  end

  def execute
    # fetch execution time limit from submission configuration
    time_limit = @config['time_limit']

    # fetch execution memory limit from submission configuration
    memory_limit = @config['memory_limit']

    # process submission in docker container
    # TODO: set user with the --user option
    # TODO: set the workdir with the -w option
    begin
      container = Docker::Container.create(
        # TODO: move entry point to docker container definition
        Cmd: ['/main.sh',
              # judge entry point
              "#{@hidden_path}/judge/run",
              # directory for logging output
              "#{@hidden_path}/logs"],
        Image: @judge.image.to_s,
        name: "dodona-#{@submission.id}", # assuming unique during execution
        OpenStdin: true,
        StdinOnce: true, # closes stdin after first disconnect
        NetworkDisabled: @config['network_disabled'],
        HostConfig: {
          Memory: memory_limit,
          MemorySwap: memory_limit, # memory including swap
          Binds: [
            # mount submission as a hidden directory (read-only)
            "#{@path}/submission:#{@hidden_path}/submission:ro",
            # mount judge resources in hidden directory (read-only)
            "#{@exercise.full_path}/evaluation:#{@hidden_path}/resources:ro",
            # mount judge definition in hidden directory (read-only)
            "#{@judge.full_path}:#{@hidden_path}/judge:ro",
            # mount logging directory in hidden directory
            "#{@path}/logs:#{@hidden_path}/logs",
            # evalution directory is read/write and seeded with copies
            "#{@path}/workdir:/home/runner/workdir",
          ]
        }
      )
    rescue Exception => e
      return handle_unknown("Error creating docker: #{e}")
    end

    begin
      stdout, stderr, exit_status = Timeout.timeout(time_limit) do
        stdout, stderr = container.tap(&:start).attach(
          stdin: StringIO.new(@config.to_json),
          stdout: true,
          stderr: true,
        )
        [stdout, stderr, container.wait(time_limit)['StatusCode']]
      end
      container.delete
      if exit_status.nonzero?
        handle_error(exit_status, stderr.join)
      else
        # submission was processed succesfully (stdout contains description of result)
        result = JSON.parse(stdout.join)
        if JSON::Validator.validate(schema_path.to_s, result)
          add_runtime_metrics(result)
          result
        else
          build_error 'internal error', 'internal error', [
            build_message(JSON::Validator.fully_validate(schema_path.to_s, result).join("\n"), 'staff')
          ]
        end
      end
    rescue Timeout::Error
      container.delete(force: true)
      handle_timeout('Docker container exceeded time limit.')
    end
  end

  def add_runtime_metrics(result)
  end

  def finalize(result)
    # save the result
    @submission.result = result.to_json
    @submission.status = Submission.normalize_status(result['status'])
    @submission.accepted = result['accepted']
    @submission.summary = result['description']
    @submission.save

    # remove path on file system used as temporary working directory for processing the submission
    unless @path.nil?
      FileUtils.remove_entry_secure(@path, verbose: true)
      @path = nil
    end
  end

  def run
    prepare
    result = execute
  rescue Exception => e
    result = build_error 'internal error', 'internal error', [
      build_message(e.message + "\n" + e.backtrace.inspect, 'staff')
    ]
  ensure
    finalize(result)
    result
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
