class ConfigParseError < StandardError
  attr_reader :repository,
              :path,
              :error_type,
              :json

  def initialize(repository, path, parse_error)
    super()
    @repository = repository
    @path = path
    # ew.
    groups = /\d+:(?<error_type>.*) at '(?<json>.*)'/m.match(parse_error)
    @error_type = groups[:error_type]
    @json = groups[:json]
  end
end
