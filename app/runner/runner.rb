require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require 'json-schema' # json schema validation, from json-schema gem
require 'tmpdir' # temporary file support

# base class for runners that have prepare-execute-finalize stages
class Runner
  def prepare
  end

  def execute
  end

  def finalize
  end
end
