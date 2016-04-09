class Exercise
  DATA_DIR = Rails.root.join('data', 'exercises').freeze
  TESTS_FILE = 'tests.js'.freeze
  DESCRIPTION_FILE = 'NL.md'.freeze
  MEDIA_DIR = 'media'.freeze
  PUBLIC_DIR = Rails.root.join('public', 'exercises').freeze

  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def tests
    file = File.join(DATA_DIR, name, TESTS_FILE)
    File.read(file) if FileTest.exists?(file)
  end

  def description
    file = File.join(DATA_DIR, name, DESCRIPTION_FILE)
    File.read(file) if FileTest.exists?(file)
  end

  def copy_media
    media_src = File.join(DATA_DIR, name, MEDIA_DIR)
    media_dst = File.join PUBLIC_DIR, name
    if FileTest.exists? media_src
      Dir.mkdir media_dst
      FileUtils.cp_r media_src, media_dst
    end
  end

  def self.all
    Dir.entries(DATA_DIR)
      .select { |entry| File.directory?(File.join(DATA_DIR, entry)) && !entry.start_with?('.') }
      .map { |entry| Exercise.new(entry) }
  end

  def self.find(name)
    return nil unless File.directory? File.join(DATA_DIR, name)
    Exercise.new(name)
  end

  def self.refresh
    msg = `cd #{DATA_DIR} && git pull 2>&1`
    status = $CHILD_STATUS.exitstatus
    Exercise.all.map(&:copy_media)
    [status, msg]
  end

  # make the partial render
  def to_partial_path
    'exercises/exercise'
  end
end
