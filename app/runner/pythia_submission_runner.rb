require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require "json-schema"	  # json schema validation, from json-schema gem
require 'tmpdir'          # temporary file support

# runner that implements the Pythia workflow of handling submissions
class PythiaSubmissionRunner < SubmissionRunner

	def initialize(submission)
		super()

		# path to the dodona json schema, used to validate judge output
		# overrides the definition from SubmissionRunner
		#TODO: get path from environment variable?
		@schema_path = 'app/runner/schemas/DodonaSubmission/output.json'
	
		# definition of submission 
		@submission = submission
		
		# derive exercise and judge definitions from submission
		@exercise = submission.exercise
		@judge = @exercise.judge
		
		# create name for hidden directory in docker container
		@hidden_path = File.join("/mnt", SecureRandom.urlsafe_base64)
		
		# submission configuration (JSON)
		@config = compose_config()
		
		# result of processing the submission (SPOJ)
		@result = nil

		# path on file system used as temporary working directory for processing the submission
		@path = nil
	end

	# calculates the difference between the biggest and smallest values
	# in a log file
	def logged_value_range(path)
		max_logged_value(path) - min_logged_value(path)
	end

	# extracts the smallest value from a log file
	def min_logged_value(path)
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
	def max_logged_value(path)
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
	def last_timestamp(path)
		t = 0

		file = File.open(path).read

		file.each_line do |line|
			# each log line has a time stamp and an actual value
			split = line.split
			t = split[0].to_i
		end

		t
	end

	def compose_config()
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
		Utils.update_config(config, @judge.config)                   # update with judge configuration
		Utils.update_config(config, @exercise.config['evaluation'])   # update with exercise configuration
		Utils.update_config(config, submission)                       # update with submission-specific configuration

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

		if exit_status != 0 then
			# error handling in class Runner
			result = handleError(exit_status, stderr)
		else
			# submission was processed succesfully (stdout contains description of result)

			result = JSON.parse(stdout)

			if JSON::Validator.validate(@schema_path, result)
				add_runtime_metrics(result)
			else
				result = ErrorBuilder.new()
							.message_description(JSON::Validator.fully_validate(@schema_path, result).join("\n"))
							.build
			end
		end

		# set result of processing the submission
		@result = result
		
	end

	def add_runtime_metrics(result)
		metrics = result["runtime_metrics"]

		if metrics == nil
			metrics = {}
		end

		if not metrics.key?("wall_time")
			value = last_timestamp(File.join(@path, 'resources', 'user_time.logs')) / 1000.0
			metrics["wall_time"] = value

			value = logged_value_range(File.join(@path, 'resources', 'user_time.logs')) / 100.0
			metrics["user_time"] = value

			value = logged_value_range(File.join(@path, 'resources', 'system_time.logs')) / 100.0
			metrics["system_time"] = value
		end

		if not metrics.key?("peak_memory")
			value = logged_value_range(File.join(@path, 'resources', 'memory_usage.logs'))
			metrics["peak_memory"] = value

			value = logged_value_range(File.join(@path, 'resources', 'anonymous_memory.logs'))
			metrics["peak_anonymous_memory"] = value
		end

		result["runtime_metrics"] = metrics
	end

	def finalize()
		# save the result
		@submission.result = @result
		@submission.save

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