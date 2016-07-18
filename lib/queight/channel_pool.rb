require "bunny"
require "connection_pool"
require "queight/channel_wrapper"

module Queight
  class ChannelPool
    DEFAULT_POOL_SIZE = 5

    def initialize(options)
      @options = options
      @wrappers = []
    end

    def with_channel
      connection_pool.with { |channel| yield(channel) }
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
      @connection_pool ||= ConnectionPool.new(connection_pool_options) do
        build_wrapper
      end
    end

    def build_wrapper
      @wrappers << ChannelWrapper.new(conn.create_channel)
      @wrappers.last
    end

    def bunny_options
      @options.merge(
        :properties => {
          :information => @options.fetch(:id, "Queight (anonymous)"),
        },
      )
    end

    def connection_pool_options
      {
        :size => @options.fetch(:size, DEFAULT_POOL_SIZE),
      }
    end
  end
end
