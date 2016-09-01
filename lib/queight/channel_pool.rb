require "bunny"
require "hot_tub"
require "queight/channel_wrapper"
require "monitor"

module Queight
  class ChannelPool
    DEFAULT_POOL_SIZE = 5

    def initialize(options)
      @options = options
      @wrappers = []
      @error_count = 0
      @lock = Monitor.new
    end

    def with_channel
      tracking_bunny_errors do
        channel_pool.run { |channel| yield(channel) }
      end
    end

    def with_transactional_channel
      tracking_bunny_errors do
        transactional_channel_pool.run { |channel| yield(channel) }
      end
    end

    def with_subscribe_channel(prefetch)
      tracking_bunny_errors do
        channel = create_channel(prefetch)
        yield(channel)
      end
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
      @tx_channel_pool ||= new_pool("pool:tx_channels")
    end

    def channel_pool
      @channel_pool ||= new_pool("pool:channels")
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

    def new_pool(name)
      HotTub::Pool.new(pool_options.merge(:name => name)) { build_wrapper }
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

    def tracking_bunny_errors
      val = yield

      no_bunny_error

      return val
    rescue Bunny::Exception => e
      bunny_error
      raise e
    end

    MAXIMUM_BUNNY_ERRORS = 3

    def bunny_error
      @error_count += 1
      synch { reconnect! if @error_count > MAXIMUM_BUNNY_ERRORS }
    end

    def no_bunny_error
      @error_count = 0
    end

    def synch
      @lock.synchronize { yield }
    end

    def reconnect!
      channel_pool.drain!
      transactional_channel_pool.drain!
      @conn.close if @conn
      @conn = nil
      @wrappers = []
      @error_count = 0
    end
  end
end
