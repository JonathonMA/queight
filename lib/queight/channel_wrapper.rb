require "forwardable"

module Queight
  # Adds memoization of exchanges etc.
  class ChannelWrapper
    extend Forwardable

    def initialize(channel)
      @channel = channel
      reset_cache!
    end

    def reset_cache!
      @exchange_cache = {}
    end

    def_delegators :@channel, :queue

    def exchange(*args)
      @exchange_cache[args] ||= @channel.exchange(*args)
    end
  end
end
