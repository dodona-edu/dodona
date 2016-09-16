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

  def compose_config
    config = super

    # set links to resources in docker container needed for processing submission
    config.recursive_update('home' => File.join(@hidden_path, 'resources', 'judge'),
                            'source' => File.join(@hidden_path, 'submission', 'source.py'))

    config
  end
end
