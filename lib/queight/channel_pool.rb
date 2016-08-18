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
      channel_pool.run { |channel| yield(channel) }
    end

    def with_transactional_channel
      transactional_channel_pool.run { |channel| yield(channel) }
    end

    def with_subscribe_channel(prefetch)
      channel = create_channel(prefetch)
      yield(channel)
    ensure
      channel.close
    end

    def create_channel(prefetch = nil)
      channel = conn.create_channel
      channel.prefetch(prefetch) if prefetch

      channel
    end

    def reset_cache!
      @wrappers.each(&:reset_cache!)
    end

    private

    def conn
      @conn ||= Bunny.new(bunny_options).tap(&:start)
    end

    def transactional_channel_pool
      @tx_channel_pool ||= HotTub::Pool.new(pool_options) { build_wrapper }
    end

    def channel_pool
      @channel_pool ||= HotTub::Pool.new(pool_options) { build_wrapper }
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
