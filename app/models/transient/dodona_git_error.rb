class DodonaGitError < StandardError
  attr_reader :repository,
              :errorstring

  def initialize(repository, error)
    super()
    @repository = repository
    @errorstring = error.to_s
  end
end
