require "bunny"
require "hot_tub"
require "queight/channel_wrapper"

module Queight
  class ChannelPool
    DEFAULT_POOL_SIZE = 5

    def initialize(options)
      @options = options
      @wrappers = []
    end

    def with_channel
      connection_pool.run { |channel| yield(channel) }
    end

    def with_subscribe_channel(prefetch)
      conn.create_channel.tap do |channel|
        channel.prefetch(prefetch)
        yield(channel)
        channel.close
      end
    end

    def reset_cache!
      @wrappers.each(&:reset_cache!)
    end

    private

    def conn
      @conn ||= Bunny.new(bunny_options).tap(&:start)
    end

    def connection_pool
      @connection_pool ||= HotTub::Pool.new(pool_options) { build_wrapper }
    end

    def build_wrapper
      @wrappers << ChannelWrapper.new(conn.create_channel)
      @wrappers.last
    end

    def bunny_options
      @options.merge(
        :properties => {
          :information => @options.fetch(:id, "Queight (anonymous)"),
        }
      )
    end

    def pool_options
      {
        :close => :close,
        :size => pool_size,
        :max_size => (pool_size * 3),
      }
    end

    def pool_size
      @options.fetch(:size, DEFAULT_POOL_SIZE)
    end
  end
end
