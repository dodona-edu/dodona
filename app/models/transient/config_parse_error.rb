class ConfigParseError < StandardError
  attr_reader :repository,
              :path,
              :error_type,
              :json

  def initialize(repository, path, parse_error)
    @repository = repository
    @path = path
    # ew.
    groups = /\d+:(?<error_type>.*) at '(?<json>.*)'/m.match(parse_error)
    @error_type = groups[:error_type]
    @json = groups[:json]
  end
end

class AggregatedConfigErrors < StandardError
  attr_reader :repository,
              :errors

  def initialize(repository, errors)
    @repository = repository
    @errors = errors.uniq(&:path)
  end
end
