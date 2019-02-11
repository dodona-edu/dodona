module Cacheable
  extend ActiveSupport::Concern

  class_methods do
    def create_cacheable(name, cache_string, calculator)
      define_method(name) do |options = {}|
        if Random.rand < 0.001
          value = calculator.call(self, options)
          Rails.cache.write(cache_string.call(self, options), value)
          return value
        end
        Rails.cache.fetch(cache_string.call(self, options)) do
          calculator.call(self, options)
        end
      end

      define_method("invalidate_#{name}".to_sym) do |options = {}|
        name = cache_string.call(self, options)
        value = Rails.cache.read(name)
        Rails.cache.write(name, value, expires_in: 5.minutes) if value.present?
      end
    end
  end
end
