
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
