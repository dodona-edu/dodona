class ParseError < StandardError
  attr_reader :file, :error

  def initialize(file, error)
    @file = file
    @error = error
  end
end
