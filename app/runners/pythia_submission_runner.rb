
# runner that implements the Pythia workflow of handling submissions
class PythiaSubmissionRunner < SubmissionRunner
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
