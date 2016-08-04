require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require 'json-schema' # json schema validation, from json-schema gem
require 'tmpdir' # temporary file support

# base class for runners that handle Dodona submissions
class SubmissionRunner < Runner
  # ADT to store to recognize an error
  # 'codes' is a list of possible exit codes that could come from this error
  # 'tokens' is a list of possible substrings that could occur in the stderr of the error
  class ErrorIdentifier
    def initialize(codes, tokens)
      @codes = codes
      @tokens = tokens
    end

    attr_reader :tokens

    attr_reader :codes
  end

  class ErrorBuilder
    def initialize
      @accepted = false
      @status = 'runtime error'
      @description = 'runtime error'

      @message_permission = 'zeus'
      @message_format = 'code'
      @message_description = ''
    end

    def build
      message = {}
      message['format'] = @message_format
      message['description'] = @message_description
      message['permission'] = @message_permission

      result = {}
      result['accepted'] = @accepted
      result['status'] = @status
      result['description'] = @description
      result['messages'] = [message]

      result
    end

    def accepted(a)
      @accepted = a
      self
    end

    def status(s)
      @status = s
      self
    end

    def description(d)
      @description = d
      self
    end

    def message_format(mf)
      @message_format = mf
      self
    end

    def message_description(md)
      @message_description = md
      self
    end

    def message_permission(mp)
      @message_permission = mp
      self
    end
  end

  def self.inherited(cl)
    @runners ||= [SubmissionRunner]
    @runners << cl
  end

  def self.runners
    @runners
  end

  def initialize
    # path to the default submission json schema, used to validate judge output
    # TODO: get path from environment variable?
    @schema_path = 'public/schemas/Submission/output.json'

    # fields to recognize and handle errors
    @error_identifiers = {}
    @error_handlers = {}

    # container receives signal 9 from host when memory limit is exceeded
    register_error('memory limit', ErrorIdentifier.new([1], ['got signal 9']), method(:handle_memory_exceeded))

    # default exit codes of the timeout command
    register_error('time limit', ErrorIdentifier.new([9, 124, 137], []), method(:handle_timeout))

    # something else
    register_error('internal error', ErrorIdentifier.new([], []), method(:handle_unknown))
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
    ErrorBuilder.new
                .status('time limit exceeded')
                .description('time limit exceeded')
                .message_description(stderr)
                .build
  end

  # adds the specific information to an output json for memory limit errors
  def handle_memory_exceeded(stderr)
    ErrorBuilder.new
                .status('memory limit exceeded')
                .description('memory limit exceeded')
                .message_description(stderr)
                .build
  end

  # adds the specific information to an output json for unknown/general errors
  def handle_unknown(stderr)
    ErrorBuilder.new
                .message_description(stderr)
                .build
  end
end
