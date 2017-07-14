require 'json'         # JSON support
require 'fileutils'    # file system utilities
require 'securerandom' # random string generators (supports URL safety)
require 'tmpdir'       # temporary file support
require 'docker'       # docker client
require 'timeout'      # to kill the docker after a certain time
require 'pathname'     # better than File

# base class for runners that handle Dodona submissions
class SubmissionRunner
  DEFAULT_CONFIG_PATH = Rails.root.join('app/runners/config.json').freeze

  def self.inherited(cl)
    @runners << cl
  end

  class << self
    attr_reader :runners
  end

  def initialize(submission)
    # definition of submission
    @submission = submission

    # derive exercise and judge definitions from submission
    @exercise = submission.exercise
    @judge = @exercise.judge

    # create name for hidden directory in docker container
    @mountsrc = nil # created when running
    @mountdst = Pathname.new("/mnt")
    @hidden_path = SecureRandom.urlsafe_base64

    # submission configuration (JSON)
    @config = compose_config

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
    config.recursive_update('resources' => (@mountdst + @hidden_path + 'resources').to_path,
                            'source'    => (@mountdst + @hidden_path + 'submission' + 'source').to_path,
                            'judge'     => (@mountdst + @hidden_path + 'judge').to_path,
                            'workdir'   => '/home/runner/workdir')

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
    (@mountsrc + @hidden_path).mkdir
    (@mountsrc + @hidden_path + 'submission').mkdir
    (@mountsrc + @hidden_path + 'submission' + 'source').open('w') do |file|
      file.write(@submission.code)
    end

    # put workdir, evaluation and judge directories in working directory
    copy_or_create(@exercise.full_path + 'workdir', @mountsrc + 'workdir')
    copy_or_create(@exercise.full_path + 'evaluation', @mountsrc + @hidden_path + 'resources')
    copy_or_create(@judge.full_path, @mountsrc + @hidden_path + 'judge')

    # ensure logs directory exist before mounting
    begin (@mountsrc + @hidden_path + 'logs').mkdir rescue Errno::EEXIST end
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
              (@mountdst + @hidden_path + 'judge' + 'run').to_path,
              # directory for logging output
              (@mountdst + @hidden_path + 'logs').to_path],
        Image: @judge.image.to_s,
        name: "dodona-#{@submission.id}", # assuming unique during execution
        OpenStdin: true,
        StdinOnce: true, # closes stdin after first disconnect
        NetworkDisabled: !@config['network_enabled'],
        HostConfig: {
          Memory: memory_limit,
          MemorySwap: memory_limit, # memory including swap
          Binds: ["#{@mountsrc}:#{@mountdst}",
                  "#{@mountsrc + 'workdir'}:#{@config['workdir']}"]
        }
      )
    rescue Exception => e
      return build_error 'internal error', 'internal error', [
        build_message("Error creating docker: #{e}", 'staff', 'plain'),
        build_message(e.backtrace.join("\n"), 'staff')
      ]
    end

    # run the container with a timeout.
    timer = Thread.new { sleep time_limit ; container.stop }
    outlines, errlines = container.tap(&:start).attach(
      stdin: StringIO.new(@config.to_json),
      stdout: true,
      stderr: true
    )
    timer.kill
    timer.join

    stdout = outlines.join
    stderr = errlines.join
    exit_status = container.wait(1)['StatusCode']
    container.delete

    # handling judge output
    if exit_status.nonzero? && exit_status != 143
      return build_error 'internal error', 'internal error', [
        build_message("Judge exited with status code #{exit_status}.", 'staff', 'plain'),
        build_message("Standard Error:", 'staff', 'plain'),
        build_message(stderr, 'staff'),
        build_message("Standard Output:", 'staff', 'plain'),
        build_message(stdout, 'staff'),
      ]
    end

    begin
      rc = ResultConstructor.new
      rc.feed(stdout)
      rc.result
    rescue ResultConstructorError => e
      if exit_status == 143
        build_error 'time limit exceeded', 'time limit exceeded', [
          build_message("Judge exited with status code #{exit_status}.", 'staff', 'plain'),
          build_message("Standard Error:", 'staff', 'plain'),
          build_message(stderr, 'staff'),
          build_message("Standard Output:", 'staff', 'plain'),
          build_message(stdout, 'staff'),
        ]
      else
        build_error 'internal error', 'internal error', [
          build_message(e.title, 'staff', 'plain'),
          build_message(e.description, 'staff'),
        ]
      end
    end
  end

  def add_runtime_metrics(result); end

  def finalize(result)
    # save the result
    @submission.result = result.to_json
    @submission.status = Submission.normalize_status(result[:status])
    @submission.accepted = result[:accepted]
    @submission.summary = result[:description]
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

end
