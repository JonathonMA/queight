require "queight/channel_pool"

module Queight
  class ConnectionCache
    def initialize
      @cache ||= {}
    end

    def reset_cache!
      @cache.values.each(&:reset_cache!)
    end

    def call(options)
      @cache[options] ||= ChannelPool.new(options)
    end
  end
end
