module Queight
  class Queue
    def initialize(name, options = {})
      @name = name
      @routing_patterns = Array(options.delete(:routing))
      @queue_options = options
    end

    attr_reader :routing_patterns, :name

    def declare(channel)
      queue(channel)
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

    def message_count(channel)
      queue(channel).message_count
    end

    def purge(channel)
      queue(channel).purge
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
