require "queight/version"
require "queight/client"
require "queight/connection_cache"
require "queight/exchange"
require "queight/queue"
require "queight/rabbitmq_config"

module Queight
  GlobalConnectionCache = ConnectionCache.new

  def self.queue(name, *routing_patterns)
    Queue.new(name, *routing_patterns)
  end

  def self.topic(name, message_options = {})
    Exchange.new(:topic, name, message_options)
  end

  def self.direct(name, message_options = {})
    Exchange.new(:direct, name, message_options)
  end

  def self.fanout(name, message_options = {})
    Exchange.new(:fanout, name, message_options)
  end

  def self.current
    options = RabbitMQConfig.configure_from!("RABBITMQ_URL").config
    channel_pool = GlobalConnectionCache.call(options)
    Client.new(channel_pool)
  end
end
