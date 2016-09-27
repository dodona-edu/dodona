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

  def add_runtime_metrics(result)
    metrics = result['runtime_metrics']

    metrics = {} if metrics.nil?

    unless metrics.key?('wall_time')
      value = last_timestamp(File.join(@path, 'logs', 'user_time.logs')) / 1000.0
      metrics['wall_time'] = value

      value = logged_value_range(File.join(@path, 'logs', 'user_time.logs')) / 100.0
      metrics['user_time'] = value

      value = logged_value_range(File.join(@path, 'logs', 'system_time.logs')) / 100.0
      metrics['system_time'] = value
    end

    unless metrics.key?('peak_memory')
      value = logged_value_range(File.join(@path, 'logs', 'memory_usage.logs'))
      metrics['peak_memory'] = value

      value = logged_value_range(File.join(@path, 'logs', 'anonymous_memory.logs'))
      metrics['peak_anonymous_memory'] = value
    end

    result['runtime_metrics'] = metrics
  end
end
