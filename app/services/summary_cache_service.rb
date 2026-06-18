require "json"

class SummaryCacheService
  class << self
    def fetch(key)
      raw = redis.get(key)
      return nil if raw.nil?
      JSON.parse(raw, symbolize_names: true)
    end

    def write(key, summary_hash)
      redis.set(key, JSON.generate(summary_hash))
      summary_hash
    end

    def delete(key)
      redis.del(key)
    end

    def lock(key, ttl: 60)
      redis.set("lock:#{key}", 1, nx: true, ex: ttl)
    end

    def unlock(key)
      redis.del("lock:#{key}")
    end

    private

    def redis
      Redis.new(url: ENV["REDIS_URL"])
    end
  end
end
