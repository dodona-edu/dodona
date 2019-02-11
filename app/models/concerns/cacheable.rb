module Cacheable
  extend ActiveSupport::Concern

  class_methods do
    def create_cacheable(name, cache_string, calculator)
      define_method(name) do |options = {}|
        if Random.rand < 0.001
          value = calculator.call(self, options)
          Rails.cache.write(cache_string.call(self, options), [false, value])
          return value
        end
        Rails.cache.fetch(cache_string.call(self, options)) do
          [false, calculator.call(self, options)]
        end[1]
      end

      define_method("invalidate_#{name}".to_sym) do |options = {}|
        lookup_string = cache_string.call(self, options)
        value = Rails.cache.read(lookup_string)
        Rails.cache.write(lookup_string, [true, value[1]], expires_in: 5.minutes) if value.present? && !value[0]
      end
    end
  end
end
