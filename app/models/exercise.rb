class Exercise
  DATA_DIR = Rails.root.join('data', 'exercises').freeze
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def tests
    file = File.join(DATA_DIR, name, 'tests.js')
    File.read(file) if FileTest.exists?(file)
  end

  def self.all
    Dir.entries(DATA_DIR)
      .select { |entry| File.directory?(File.join(DATA_DIR, entry)) && !(entry == '.' || entry == '..') }
      .map { |entry| Exercise.new(entry) }
  end

  def self.find(name)
    return nil unless File.directory? File.join(DATA_DIR, name)
    Exercise.new(name)
  end

  # make the partial render
  def to_partial_path
    'exercises/exercise'
  end
end
