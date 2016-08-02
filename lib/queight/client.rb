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

    def with_transactional_channel
      @channel_pool.with_transactional_channel do |channel|
        yield(channel)
      end
    end

    def with_subscribe_channel(prefetch)
      @channel_pool.with_subscribe_channel(prefetch) do |channel|
        yield(channel)
      end
    end

    def declare(queue)
      with_channel do |channel|
        queue.declare(channel)
      end
    end

    def publish(exchange, message, routing_key)
      with_transactional_channel do |channel|
        channel.tx_select
        exchange.publish(channel, message, routing_key)
        raise PublishFailure unless channel.tx_commit
      end
    end

    def publish_without_transaction(exchange, message, routing_key)
      with_channel do |channel|
        exchange.publish(channel, message, routing_key)
      end
    end
    alias publish! publish_without_transaction

    def publish_to_queue(message, queue, message_options = {})
      declare(queue)
      publish(Queight.default_exchange(message_options), message, queue.name)
    end

    def publish_to_queue_without_transaction(message, queue, options = {})
      declare(queue)
      publish_without_transaction(
        Queight.default_exchange(options),
        message,
        queue.name
      )
    end
    alias publish_to_queue! publish_to_queue_without_transaction

    def subscribe(queue, prefetch = 1, &block)
      with_subscribe_channel(prefetch) do |channel|
        queue.subscribe(channel, &block)
      end
    end

    def bind(exchange, queue)
      with_channel do |channel|
        exchange.bind(channel, queue)
      end
    end

    def message_count(queue)
      with_channel { |channel| queue.message_count(channel) }
    end

    def delete_queue(queue)
      with_channel do |channel|
        queue.delete(channel)
      end
    end

    def purge(queue)
      with_channel { |channel| queue.purge(channel) }
    end

    def delete_exchange(exchange)
      with_channel do |channel|
        exchange.delete(channel)
      end
    end
  end
end
