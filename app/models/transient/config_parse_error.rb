class ConfigParseError < StandardError
  attr_reader :path, :message

  def initialize(path, message)
    @path = path
    @message = message
  end
end
