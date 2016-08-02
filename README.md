# Queight

[![Build Status](https://travis-ci.org/JonathonMA/queight.svg?branch=master)](https://travis-ci.org/JonathonMA/queight)

This is a lightweight wrapper around the `bunny` gem. It tries to handle caching the rabbitmq connection and channels in a sensible way:

- The main connection is cached globally.
- Channels are allocated from a pool since they are not thread safe.
- Channels for subscribers are allocated one-off and specify a prefetch.

This matches our normal usage of rabbitmq, with publishing happening constantly throughout usage, while subscription is usually a dedicated process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'queight'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install queight

## Usage

First configure your environment:

    RABBITMQ_URL=amqp://username:password@hostname:port

You can use the following query parameters to further customize behaviour:

| parameter | effect                |
| --------- | --------------------- |
| size      | connection pool size  |
| id        | client identification |

Then you can get a Queight client:

    client = Queight.current

In order to publish messages you'll need an exchange:

    topic_exchange = Queight.topic "exchange.topic"
    direct_exchange = Queight.direct "exchange.direct"

And in order to subscribe to queues you'll need a queue:

    queue = Queight.queue("queue.name")

Then you can just publish messages using the client and the exchange:

    client.publish(topic_exchange, "message", "routing.key")

Note that publishing uses transactions by default (slow!), so if you're ok with messages hitting the floor and not knowing about it, try:

    client.publish_without_transaction(topic_exchange, "message", "routing.key")

### Publishing to a topic exchange

```ruby
exchange = Queight.topic("test.exchange.topic")
message = JSON.dump(id: 1, message: "hello")
routing_key = "message.1"
client.publish(exchange, message, routing_key)
queue = Queight.queue("test.queue1")

client = Queight.current
```

### Binding queues

```ruby
exchange = Queight.topic("exchange.name")
# Declare a queue and routing patterns
queue = Queight.queue("queue.name", routing: ["message.#", "reply.#"])
client.bind(exchange, queue)
```

### Subscribing to messages from a queue

Subscribing by default will block and require manual ack.

``` ruby
client.subscribe(queue) do |channel, delivery_info, properties, payload|
  do_something(payload)
  channel.acknowledge(delivery_info.delivery_tag)
end
```

## Development

The `.env` file assumes a rabbitmq running on localhost with a username and password of guest. The provided docker-compose.yml let's you run one with:

    docker-compose up -d

If your docker does not expose ports on localhost you may need to override this, e.g. dinghy on OS X should override in `.env.local` with:

    RABBITMQ_URL=amqp://guest:guest@queight-rabbitmq-1.docker

Alternatively, you can use the provided ruby18 and ruby23 services to run tests:

    docker-compose run --rm ruby18 bundle
    docker-compose run --rm ruby18

    docker-compose run --rm ruby23 bundle
    docker-compose run --rm ruby23

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/queight. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

