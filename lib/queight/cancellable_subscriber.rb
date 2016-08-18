module Queight
  class CancellableSubscriber
    def initialize(channel, subscriber)
      @channel = channel
      @subscriber = subscriber
    end

    def cancel
      @subscriber.cancel
      @channel.close
    end
  end
end
