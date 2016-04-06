class Exercise

  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def self.all
    [Exercise.new("test1")]
  end

  # make the partial render
  def to_partial_path
    'exercises/exercise'
  end

end
