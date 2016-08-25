require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require 'json-schema' # json schema validation, from json-schema gem
require 'tmpdir' # temporary file support

# base class for runners that handle Dodona submissions
class SubmissionRunner
  DEFAULT_CONFIG_PATH = Rails.root.join('app/runner/config.json').freeze

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

  def build_error status='runtime error', description='runtime error', messages=[], accepted=false
    {
      'accepted': accepted,
      'status': status,
      'description': description,
      'messages': messages
    }
  end

  def build_message description='', permission='zeus', format='code'
    {
      'format': format,
      'description': description,
      'permission': permission
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
    config.recursive_update({
      'programming_language': @submission.exercise.programming_language,
      'natural_language': @submission.user.lang
    })

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
end
