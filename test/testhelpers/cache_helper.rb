module CacheHelper
  def with_cache
    original_store = Rails.application.config.cache_store
    original_cache = Rails.cache
    Rails.application.config.cache_store = [:memory_store, { size: 64.megabytes }]
    Rails.cache = ActiveSupport::Cache::MemoryStore.new(
      expires_in: 1.minute
    )
    yield
  ensure
    Rails.cache.clear
    Rails.cache = original_cache
    Rails.application.config.cache_store = original_store
  end
end
