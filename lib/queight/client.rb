module Queight
  class Client
    PublishFailure = Class.new(StandardError)

    def initialize(channel_pool)
      @channel_pool = channel_pool
    end

    def with_channel
      @channel_pool.with_channel do |channel|
        yield(channel)
      end
    end

    def with_subscribe_channel(prefetch)
      @channel_pool.with_subscribe_channel(prefetch) do |channel|
        yield(channel)
      end
    end

    def publish_without_transaction(config, message, routing_key)
      with_channel do |channel|
        config.publish(channel, message, routing_key)
      end
    end

    def publish(exchange, message, routing_key)
      with_channel do |channel|
        channel.tx_select
        exchange.publish(channel, message, routing_key)
        raise PublishFailure unless channel.tx_commit
      end
    end

    # TODO: subscribe, sudddenly, a wild prefetch appears
    def subscribe(queue, prefetch = 1, &block)
      with_subscribe_channel(prefetch) do |channel|
        queue.subscribe(channel, &block)
      end
    end

    def bind(exchange, queue)
      with_channel do |channel|
        queue.bind_to(channel, exchange)
      end
    end

    def delete_queue(queue)
      with_channel do |channel|
        queue.delete(channel)
      end
    end

    def delete_exchange(config)
      with_channel do |channel|
        config.delete(channel)
      end
    end
  end
end
