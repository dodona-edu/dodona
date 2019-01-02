module Cacheable
  extend ActiveSupport::Concern

  class_methods do
    def create_cacheable(name, cache_string, calculator)
      define_method(name) do |options = {}|
        if Random.rand < 0.001
          value = calculator.call(self, options)
          Rails.cache.write(cache_string.call(self, options), value, expires_in: 1.hour)
          return value
        end
        Rails.cache.fetch(cache_string.call(self, options), expires_in: 1.hour) do
          calculator.call(self, options)
        end
      end
    end
  end
end
