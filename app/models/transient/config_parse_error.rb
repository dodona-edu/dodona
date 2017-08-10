class ConfigParseError < StandardError
  attr_reader :path, :error_type, :json

  def initialize(path, parse_error)
    @path = path
    # ew.
    groups = /\d+:(?<error_type>.*) at '(?<json>.*)'/m.match(parse_error)
    @error_type = groups[:error_type]
    @json = groups[:json]
  end
end
