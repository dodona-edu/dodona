require 'json'            # JSON support
require 'open3'           # process management
require 'fileutils'       # file system utilities
require 'securerandom'    # random string generators (supports URL safety)
require "json-schema"	  # json schema validation, from json-schema gem
require 'tmpdir'          # temporary file support

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
		@schema_path = 'app/runner/schemas/Submission/output.json'

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