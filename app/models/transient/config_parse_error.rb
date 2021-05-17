class ConfigParseError < StandardError
  attr_reader :repository,
              :path,
              :error_type,
              :json

  def initialize(repository, path, error_type, json)
    super()
    @repository = repository
    @path = path
    @error_type = error_type
    @json = json
  end
end
