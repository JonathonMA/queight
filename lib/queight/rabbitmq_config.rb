require "uri_config/config"

module Queight
  class RabbitMQConfig < URIConfig::Config
    map :user, from: :username

    def size
      query["size"].map(&:to_i).last
    end

    config :user, :password, :port, :host, :size
  end
end
