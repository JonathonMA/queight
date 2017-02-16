require "uri_config/config"
require "uri"

module Queight
  class RabbitMQConfig < URIConfig::Config
    map :user, :from => :username

    def size
      query["size"].map(&:to_i).last
    end

    def vhost
      return "/" if path.empty?

      URI.decode path[1..-1]
    end

    parameter :id

    config :user, :password, :port, :host, :vhost, :size, :id
  end
end
