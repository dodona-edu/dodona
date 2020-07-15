Warning.singleton_class.prepend(
  Module.new do

    # Ignore warnings originating in gems.
    PATTERN = %r{/gems/.*(Passing the keyword argument as the last hash parameter is deprecated|Using the last argument as keyword parameters is deprecated)|The called method( `.+')? is defined here}.freeze

    def warn(warning)
      super unless warning.match?(PATTERN)
    end
  end
)
