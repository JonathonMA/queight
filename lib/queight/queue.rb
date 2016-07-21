module Queight
  class Queue
    def initialize(name, options = {})
      @name = name
      @routing_patterns = Array(options.delete(:routing))
      @queue_options = options
    end

    def bind_to(channel, exchange_config)
      exchange = exchange_config.exchange(channel)
      queue = queue(channel)
      if @routing_patterns.any?
        @routing_patterns.each do |routing_pattern|
          queue.bind(exchange, :routing_key => routing_pattern)
        end
      else
        queue.bind(exchange)
      end
    end

    def subscribe(channel)
      queue = queue(channel)
      queue.subscribe(subscribe_options) do |*args|
        yield(channel, *args)
      end
    end

    def delete(channel)
      channel.queue(@name).delete
    end

    def queue(channel)
      channel.queue(@name, queue_options)
    end

    private

    def subscribe_options
      {
        :block => true,
        :manual_ack => true,
      }
    end

    def queue_options
      {
        :auto_delete => false,
        :durable => true,
        :exclusive => false,
      }.merge(@queue_options)
    end
  end
end
