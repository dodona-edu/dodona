class AggregatedConfigErrors < StandardError
  include Enumerable

  attr_reader :repository,
              :errors

  def initialize(repository, errors)
    super()
    @repository = repository
    @errors = errors.uniq(&:path)
  end

  def each(&)
    errors.each(&)
  end
end
