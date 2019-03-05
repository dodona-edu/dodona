module Cacheable
  extend ActiveSupport::Concern

  CACHE_BYPASS_CHANCE = 0.001
  CACHE_EXPIRY_TIME = 5.minutes

  class_methods do
    def create_cacheable(name, cache_string)
      calculator = instance_method(name)
      define_method(name) do |options = {}|
        if Random.rand < CACHE_BYPASS_CHANCE || options[:force]
          value = calculator.bind(self).(options)
          Rails.cache.write(cache_string.call(self, options), [false, value])
          return value
        end
        Rails.cache.fetch(cache_string.call(self, options)) do
          [false, calculator.bind(self).(options)]
        end[1]
      end

      define_method("invalidate_#{name}".to_sym) do |options = {}|
        lookup_string = cache_string.call(self, options)
        value = Rails.cache.read(lookup_string)
        Rails.cache.write(lookup_string, [true, value[1]], expires_in: CACHE_EXPIRY_TIME) if value.present? && !value[0]
      end
    end
  end
end
