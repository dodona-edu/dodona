class AggregatedConfigErrors < StandardError
  include Enumerable

  attr_reader :repository,
              :errors

  def initialize(repository, errors)
    @repository = repository
    @errors = errors.uniq(&:path)
  end

  def each(&block)
    errors.each(&block)
  end
end
