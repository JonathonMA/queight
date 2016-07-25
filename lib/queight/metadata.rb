module Queight
  # Provides interface like AMQP::Header
  class Metadata
    def initialize(channel, delivery_info, properties)
      @channel = channel
      @delivery_info = delivery_info
      @properties = properties
    end

    def ack
      @channel.acknowledge(@delivery_info.delivery_tag)
    end

    def reject(options = {})
      requeue = options.fetch(:requeue, false)
      @channel.reject(@delivery_info.delivery_tag, requeue)
    end

    def redelivered?
      @delivery_info.redelivered?
    end
  end
end
