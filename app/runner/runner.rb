require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require "json-schema"	  # json schema validation, from json-schema gem
require 'tmpdir'          # temporary file support

# base class for runners that have prepare-execute-finalize stages
class Runner
	
	def prepare
	end

	def execute
	end

	def finalize
	end
	
end

# base class for runners that handle Dodona submissions
class SubmissionRunner < Runner
	# ADT to store to recognize an error
	# 'codes' is a list of possible exit codes that could come from this error
	# 'tokens' is a list of possible substrings that could occur in the stderr of the error
	class ErrorIdentifier
	
		def initialize(codes, tokens)
			@codes = codes
			@tokens = tokens
		end

		def tokens
			@tokens
		end

		def codes
			@codes
		end
		
	end

	class ErrorBuilder

		def initialize
			@accepted = false
			@status = 'runtime error'
			@description = 'runtime error'

			@message_permission = 'teacher'
			@message_format = 'text'
			@message_description = ''
		end

		def build
			message = {}
			message["format"] = @message_format
			message["description"] = @message_description
			message["permission"] = @message_permission
			
			result = {}
			result["accepted"] = @accepted
			result["status"] = @status
			result["description"] = @description
			result["messages"] = [message]

			return result
		end

		def accepted(a)
			@accepted = a
			self
		end

		def status(s)
			@status = s
			self
		end

		def description(d)
			@description = d
			self
		end

		def message_format(mf)
			@message_format = mf
			self
		end

		def message_description(md)
			@message_description = md
			self
		end

		def message_permission(mp)
			@message_permission = mp
			self
		end
	end

	def initialize

		# path to the default submission json schema, used to validate judge output
		#TODO: get path from environment variable?
		@schema_path = 'app/runner/runners/Submission/output.json'

		# fields to recognize and handle errors
		@error_identifiers = {}
		@error_handlers = {}

		# container receives signal 9 from host when memory limit is exceeded
		registerError('memory limit', ErrorIdentifier.new([1], ['got signal 9']), method(:handleMemoryExceeded))

		# default exit codes of the timeout command
		registerError('time limit', ErrorIdentifier.new([9, 124, 137], []), method(:handleTimeout))

		# something else
		registerError('internal error', ErrorIdentifier.new([], []), method(:handleUnknown))
		
	end

	# registers a pair of error identifiers and error handlers with the same identifier string (name)
	def registerError(name, identifier, handler)
		@error_identifiers[name] = identifier
		@error_handlers[name] = handler
	end

	# uses the exitcode and stderr to recognize which error occured
	# returns a string identifier of the error
	def recognizeError(exitcode, stderr)

		@error_identifiers.keys.each do |key|
			# loop over all the error identifiers
			identifier = @error_identifiers[key]
			codes = identifier.codes
			tokens = identifier.tokens

			# the process's exit code must be in the error identifier's list
			if codes.include?(exitcode) then

				# if the token list is empty, the exit code is enough
				# if not, one token must match the process's stderr
				if tokens.empty? or tokens.any? {|token| stderr.include?(token)} then
					return key
				end
			end
			
		end

		# this is some serious error
		return 'internal error'
		
	end

	# uses the exitcode and stderr to generate output json
	def handleError(exitcode, stderr)
	
		# figure out which error occured
		error = recognizeError(exitcode, stderr)

		# fetch the correct handler
		handler = @error_handlers[error]

		# let the handler fill in the blanks
		handler.call(stderr)
		
	end

	# adds the specific information to an output json for timeout errors
	def handleTimeout(stderr)
	
		ErrorBuilder.new()
			.status("time limit exceeded")
			.description("time limit exceeded")
			.message_description(stderr)
			.build
		
	end

	# adds the specific information to an output json for memory limit errors
	def handleMemoryExceeded(stderr)
	
		ErrorBuilder.new()
			.status("memory limit exceeded")
			.description("memory limit exceeded")
			.message_description(stderr)
			.build
		
	end

	# adds the specific information to an output json for unknown/general errors
	def handleUnknown(stderr)
	
		ErrorBuilder.new()
			.message_description(stderr)
			.build
		
	end
end

# runner that implements the Pythia workflow of handling submissions
class PythiaSubmissionRunner < SubmissionRunner

	def initialize(submission)
		super()

		# path to the dodona json schema, used to validate judge output
		# overrides the definition from SubmissionRunner
		#TODO: get path from environment variable?
		@schema_path = 'app/runner/runners/DodonaSubmission/output.json'
	
		# definition of submission 
		@submission = submission
		
		# derive exercise and judge definitions from submission
		@exercise = submission.exercise
		@judge = @exercise.judge
		
		# create name for hidden directory in docker container
		@hidden_path = File.join("/mnt", SecureRandom.urlsafe_base64)
		
		# submission configuration (JSON)
		@config = composeConfig()
		
		# result of processing the submission (SPOJ)
		@result = nil

		# path on file system used as temporary working directory for processing the submission
		@path = nil
	end

	# TODO: implement as utility function/method since Exercise and Judge classes need it as well
	# 		rename to mergeHash? shouldn't use a specific name like updateConfig once it's a utility function
	def updateConfig(original, source)
	
		source.keys.each do |key|
			value = source[key]
			if original.include?(key)
				if value.class != original[key].class  
					# merging in this case wouldn't make sense
					raise 'merging incompatible hashes'
				elsif value.class == Hash 
					# hashes get merged recursively
					updateConfig(original[key], value)
				else
					# other values get overwritten
					original[key] = value
				end
			else
				# original doesn't contain this key yet, merging is easy
				original[key] = value
			end
		end
		
	end

	# calculates the difference between the biggest and smallest values
	# in a log file
	def loggedValueRange(path)
		maxLoggedValue(path) - minLoggedValue(path)
	end

	# extracts the smallest value from a log file
	def minLoggedValue(path)
		m = nil

		file = File.open(path).read

		file.each_line do |line|
			# each log line has a time stamp an actual value
			split = line.split
			value = split[1].to_i

			if m == nil or value < m 
				m = value
			end
		end

		m
	end

	# extracts the biggest value from a log file
	def maxLoggedValue(path)
		m = -1

		file = File.open(path).read

		file.each_line do |line|
			# each log line has a time stamp and an actual value
			split = line.split
			value = split[1].to_i
			if value > m 
				m = value
			end
		end

		m
	end

	# extracts the last timestamp from a log file
	# TODO: cleaner way to get last line from file?
	def lastTimeStamp(path)
		t = 0

		file = File.open(path).read

		file.each_line do |line|
			# each log line has a time stamp and an actual value
			split = line.split
			t = split[0].to_i
		end

		t
	end

	def composeConfig()
		# set submission-specific configuration
		submission = {}
	
		# set programming language of submission
		submission["programming_language"] = @submission.exercise.programming_language

		# set natural language of submission
		submission["natural_language"] = I18n.locale.to_s		

		# set links to resources in docker container needed for processing submission
		submission["home"] = File.join(@hidden_path, "resources", "judge")
		submission["source"] = File.join(@hidden_path, "submission", "source.py")

		# compose submission configuration
		#TODO, get from environment variable? or hard code some values?
		config_defaults_path = "app/runner/config.json"
		config = JSON.parse(File.read(config_defaults_path))   # set default configuration
		updateConfig(config, @judge.config)                   # update with judge configuration
		updateConfig(config, @exercise.config['evaluation'])   # update with exercise configuration
		updateConfig(config, submission)                       # update with submission-specific configuration

		puts config
		# return the submission configuration
		return config
	end

	def prepare()
		# create path on file system used as temporary working directory for processing the submission
		# TODO: decide where temporary directories should go on the Dodona server
		@path = Dir.mktmpdir()

		# put submission in working directory (subdirectory submission)
		Dir.mkdir("#{@path}/submission/")
		open("#{@path}/submission/source.py", "w") {
			|file|
			file.write(@submission.code)
		}

		# put submission resources in working directory (subdirectory resources)
		Dir.mkdir("#{@path}/resources/")
		src = File.join(@exercise.path, "evaluation", "media")
		if File.directory?(src) then
			dest = File.join(File.join(@path, "resources"))
			FileUtils.cp_r(src, dest)
		end		

		# otherwise docker will make these as root
		# TODO: can we fix this?
		Dir.mkdir("#{@path}/submission/judge/")
		Dir.mkdir("#{@path}/submission/resources")

	end

	def execute()

		# fetch execution time limit from submission configuration
		time_limit = @config["time_limit"]

		# fetch execution memory limit from submission configuration
		memory_limit = @config["memory_limit"]

		# process submission in docker container 
		# TODO: somehow this creates a @path/source/resources/ directory (unwanted)
		# TODO: set user with the --user option
		# TODO: set the workdir with the -w option
		stdout, stderr, status = Open3.capture3(
			# set timeout
			'timeout', '-k', "#{time_limit}", "#{time_limit}",
			# start docker container
			'docker', 'run', 
			# activate stdin
			'-i', 
			# remove dead container
			'--rm', 
			# 'memory limit', physical mapped and swap memory?
			'--memory', "#{memory_limit}B", 
			# mount submission as a hidden directory
			# DONE: made read-only in entry point of docker container
			'-v', "#{@path}/submission:#{@hidden_path}/submission",
			# mount judge resources in hidden directory (read-only)
			'-v', "#{@exercise.full_path}/evaluation:#{@hidden_path}/resources/judge:ro", 
			# mount judge definition in hidden directory (read-only)
			'-v', "#{@judge.full_path}:#{@hidden_path}/judge:ro",
			# create runner home directory as read/write
			'-v', "#{@path}/resources:/home/runner",
			# image used to launch docker container
			"#{@judge.image}",
			# initialization script of docker container (so-called entry point of docker container)
			# TODO: move entry point to docker container definition
			# TODO: rename this into something more meaningful (suggestion: launch_runner)
			'/main.sh',
			# $1: script that starts processing the submission in the docker container
			"#{@hidden_path}/judge/run.sh", 
			# $2: hidden path
			"#{@hidden_path}",
			stdin_data:@config.to_json
		) 

		exit_status = 0

		# TODO, stopsig and termsig aren't real exit statuses
		if status.exited?
			exit_status = status.exitstatus
		elsif wait_thr.value.stopped?
			exit_status = status.stopsig
		else 
			exit_status = status.termsig
		end

		puts exit_status

		if exit_status != 0 then
			# error handling in class Runner
			result = handleError(exit_status, stderr)
		else
			# submission was processed succesfully (stdout contains description of result)

			result = JSON.parse(stdout)

			if JSON::Validator.validate(@schema_path, result)
				addRuntimeMetrics(result)
			else
				result = ErrorBuilder.new()
							.message_description(JSON::Validator.fully_validate(@schema_path, result).join("\n"))
							.build
			end
		end

		# set result of processing the submission
		@result = result
		
	end

	def addRuntimeMetrics(result)
		metrics = result["runtime_metrics"]

		if metrics == nil
			metrics = {}
		end

		if not metrics.key?("wall_time")
			value = lastTimeStamp(File.join(@path, 'resources', 'user_time.logs')) / 1000.0
			metrics["wall_time"] = value

			value = loggedValueRange(File.join(@path, 'resources', 'user_time.logs')) / 100.0
			metrics["user_time"] = value

			value = loggedValueRange(File.join(@path, 'resources', 'system_time.logs')) / 100.0
			metrics["system_time"] = value
		end

		if not metrics.key?("peak_memory")
			value = loggedValueRange(File.join(@path, 'resources', 'memory_usage.logs'))
			metrics["peak_memory"] = value

			value = loggedValueRange(File.join(@path, 'resources', 'anonymous_memory.logs'))
			metrics["peak_anonymous_memory"] = value
		end

		result["runtime_metrics"] = metrics
	end

	def finalize()
		# TODO: process result of processing the submission (e.g. put result into database)

		puts JSON.pretty_generate(@result)

		# remove path on file system used as temporary working directory for processing the submission
		if @path != nil then
			FileUtils.remove_entry_secure(@path, :verbose => true)
			@path = nil
		end
		
	end

	def run()
	
		begin
			prepare()
			execute()
		rescue Exception => e 
			@result = ErrorBuilder.new()
				.message_description(e.message + "\n" + e.backtrace.inspect)
				.build
		ensure
			finalize()
		end
		
	end
	
end