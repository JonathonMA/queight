module Queight
  # Adds memoization of exchanges etc.
  class ChannelWrapper < SimpleDelegator
    def initialize(channel)
      super(channel)
      reset_cache!
    end

    def reset_cache!
      @exchange_cache = {}
    end

    def exchange(*args)
      @exchange_cache[args] ||= super
    end
  end
end
