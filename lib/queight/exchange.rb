module Queight
  class Exchange
    def initialize(type, name, message_options = {})
      @type = type
      @name = name
      @message_options = {
        :content_type => "application/json",
        :persistent => true,
      }.merge(message_options)
    end

    def publish(channel, message, routing_key)
      exchange(channel).publish(message, message_options_for(routing_key))
    end

    def exchange(channel)
      channel.exchange(@name, exchange_options)
    end

    def delete(channel)
      channel.exchange(@name, exchange_options).delete
    end

    def bind(channel, queue)
      if queue.routing_patterns.any?
        queue.routing_patterns.each do |routing_pattern|
          queue.queue(channel).bind(
            exchange(channel),
            :routing_key => routing_pattern
          )
        end
      else
        queue.queue(channel).bind(exchange(channel))
      end
    end

    private

    def exchange_options
      {
        :auto_delete => false,
        :durable => true,
        :type => @type,
      }
    end

    def message_options_for(routing_key)
      @message_options.merge(:routing_key => routing_key)
    end
  end

  class DefaultExchange < Exchange
    def initialize(message_options = {})
      super(nil, nil, message_options)
    end

    def delete(_channel)
    end

    def bind(_channel, _queue)
    end

    def exchange(channel)
      channel.default_exchange
    end
  end
end
