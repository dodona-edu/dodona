require 'json'         # JSON support
require 'fileutils'    # file system utilities
require 'securerandom' # random string generators (supports URL safety)
require 'json-schema'  # json schema validation, from json-schema gem
require 'tmpdir'       # temporary file support
require 'docker'       # docker client
require 'timeout'      # to kill the docker after a certain time

# base class for runners that handle Dodona submissions
class SubmissionRunner
  DEFAULT_CONFIG_PATH = Rails.root.join('app/runners/config.json').freeze

  def self.inherited(cl)
    @runners ||= [SubmissionRunner]
    @runners << cl
  end

  class << self
    attr_reader :runners
  end

  # path to the default submission json schema, used to validate judge output
  def schema_path
    Rails.root.join 'public/schemas/judge_output.json'
  end

  def initialize(submission)
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
        NetworkDisabled: !@config['network_enabled'],
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
            "#{@path}/workdir:/home/runner/workdir"
          ]
        }
      )
    rescue Exception => e
      return build_error 'internal error', 'internal error', [
        build_message("Error creating docker: #{e}", 'staff', 'plain'),
        build_message(e.backtrace.join("\n"), 'staff')
      ]
    end

    begin
      # run the container with a timeout.
      stdout, stderr, exit_status = Timeout.timeout(time_limit) do
        stdout, stderr = container.tap(&:start).attach(
          stdin: StringIO.new(@config.to_json),
          stdout: true,
          stderr: true
        )
        [stdout, stderr, container.wait(time_limit)['StatusCode']]
      end
      container.delete

      # handling judge output
      if exit_status.nonzero?
        build_error 'internal error', 'internal error', [
          build_message("Judge exited with status code #{exit_status}:", 'staff', 'plain'),
          build_message(stderr.join, 'staff')
        ]
      elsif not JSON::Validator.validate(schema_path.to_s, stdout.join)
        build_error 'internal error', 'internal error', [
          build_message("Judge output is not a valid json:", 'staff', 'plain'),
          build_message(JSON::Validator.fully_validate(schema_path.to_s, stdout.join).join("\n"), 'staff'),
        ]
      else
        result = JSON.parse(stdout.join)
        add_runtime_metrics(result)
        result
      end
    rescue Timeout::Error
      container.delete(force: true)
      build_error 'time limit exceeded', 'time limit exceeded', [
        build_message('Docker container exceeded time limit.', 'staff', 'plain')
      ]
    end
  end

  def add_runtime_metrics(result); end

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

  private

  # ============================================================
  # json building helpers

  def build_error(status = 'internal error', description = 'internal error', messages = [])
    {
      'accepted' => false,
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

end
