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
end
