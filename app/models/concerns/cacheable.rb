module Cacheable
  extend ActiveSupport::Concern

  CACHE_BYPASS_CHANCE = 0.001
  CACHE_EXPIRY_TIME = 5.minutes

  class_methods do
    def invalidateable_instance_cacheable(name, cache_string)
      calculator = instance_method(name)
      define_method(name) do |options = {}|
        if Random.rand < CACHE_BYPASS_CHANCE || options[:force]
          value = calculator.bind(self).call(options)
          Rails.cache.write(cache_string.call(self, options), [false, value])
          return value
        end
        Rails.cache.fetch(cache_string.call(self, options)) do
          [false, calculator.bind(self).call(options)]
        end[1]
      end

      define_method(:"invalidate_#{name}") do |options = {}|
        lookup_string = cache_string.call(self, options)
        Rails.cache.delete(lookup_string)
      end

      define_method(:"invalidate_delayed_#{name}") do |options = {}|
        lookup_string = cache_string.call(self, options)
        value = Rails.cache.read(lookup_string)
        Rails.cache.write(lookup_string, [true, value[1]], expires_in: CACHE_EXPIRY_TIME) if value.present? && !value[0]
      end

      define_method(:"old_#{name}", calculator)
    end

    def updateable_class_cacheable(name, cache_string)
      updater = method(name)
      define_singleton_method(name) do |options = {}|
        Rails.cache.fetch(cache_string.call(options))
      end

      define_singleton_method(:"update_#{name}") do |options = {}|
        old = Rails.cache.fetch(cache_string.call(options))
        updated = if old.present?
                    updater.call(options, old)
                  else
                    updater.call(options)
                  end
        Rails.cache.write(cache_string.call(options), updated)
      end

      define_singleton_method(:"old_#{name}", updater)
    end
  end
end
