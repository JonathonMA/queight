require "spec_helper"

require "queight"
require "thread"

def exercise(client, exchange, queues, messages, publish_method = :publish)
  queues.each do |queue|
    client.declare(queue)
    client.bind(exchange, queue)
  end

  messages.each do |routing_key, message|
    client.send(publish_method, exchange, message, routing_key)
  end

  queues.each do |queue|
    test_helper.wait_for_messages(queue)
  end
end

describe Queight do
  let(:client) { Queight.current }
  let(:test_helper) { QueightTestHelper.new(client) }

  before(:each) do
    test_helper.clear
  end

  after(:each) do
    test_helper.cleanup
  end

  %w(publish publish!).each do |publish_method|
    describe "##{publish_method}" do
      it "supports the default exchange" do
        queue_name = "test.queue.direct.via_default"
        routing_key = queue_name
        messages = [
          [routing_key, message(:foo => "bar")],
        ]
        exchange = Queight.default_exchange
        queues = [
          test_helper.queue(Queight.queue(queue_name)),
        ]

        exercise(client, exchange, queues, messages, publish_method)
        result = test_helper.messages_from(*queues)

        expect(result).to eq messages.map(&:last)
      end

      it "supports direct queues" do
        routing_key = "test.routing.key"
        queue_name = "test.queue.direct"
        messages = [
          [routing_key, message(:foo => "bar")],
        ]
        exchange = test_helper.topic(Queight.direct("test.exchange.direct"))
        queues = [
          test_helper.queue(Queight.queue(queue_name, :routing => routing_key)),
        ]

        exercise(client, exchange, queues, messages, publish_method)
        result = test_helper.messages_from(*queues)

        expect(result).to eq messages.map(&:last)
      end

      it "supports fanout queues" do
        routing_key = "is.irrelevant"
        messages = [
          [routing_key, message(:foo => "bar")],
        ]
        exchange = test_helper.topic(Queight.fanout("test.exchange.fanout"))
        queues = [
          test_helper.queue(Queight.queue("test.queue1")),
          test_helper.queue(Queight.queue("test.queue2")),
        ]

        exercise(client, exchange, queues, messages, publish_method)
        result = test_helper.messages_from(*queues)

        expect(result).to eq(messages.map(&:last) * 2)
      end

      it "supports topic queues" do
        messages = %w(
          test.message.au
          test.message.nz
          test.message.gb
          test.message.ie
          test.message.us
        ).map do |key|
          [key, message(:message => key)]
        end
        routing_keys = messages.map(&:first)
        exchange = test_helper.topic(Queight.topic("test.exchange.topic"))
        queues = [
          test_helper.queue(
            Queight.queue("test.queue1", :routing => routing_keys)
          ),
        ]

        exercise(client, exchange, queues, messages, publish_method)

        result = test_helper.messages_from(*queues)

        expect(result).to eq messages.map(&:last)
      end
    end
  end

  it "is thread safe" do
    thread_count = 10
    message_count = 1000
    routing_key = "is.irrelevant"
    messages = Array.new(message_count) do |i|
      [routing_key, message(i => i.to_s)]
    end.shuffle
    exchange = test_helper.topic(Queight.direct("test.exchange.threads"))
    queues = [
      test_helper.queue(Queight.queue("test.queue1", :routing => routing_key)),
    ]

    queues.each do |queue|
      client.bind(exchange, queue)
    end

    pool = Queue.new
    messages.each do |message|
      pool << message
    end

    Array.new(thread_count) do
      Thread.new do
        while (item = pool.pop(true) rescue nil)
          routing_key, message = *item
          client.publish(exchange, message, routing_key)
        end
      end
    end.each(&:join)

    result = test_helper.messages_from(queues[0])

    expect(result.to_set).to eq messages.map(&:last).to_set
  end

  it "supports subscribing to topic queues" do
    messages = %w(
      test.message.au
      test.message.nz
      test.message.gb
      test.message.ie
      test.message.us
    ).map do |key|
      [key, message(:message => key)]
    end
    routing_keys = messages.map(&:first)
    exchange = test_helper.topic(Queight.direct("test.exchange.topic"))
    queues = [
      test_helper.queue(Queight.queue("test.queue1", :routing => routing_keys)),
    ]

    exercise(client, exchange, queues, messages)

    result = []
    # NOTE: this thread will live forever, :(
    Thread.new do
      client.subscribe(queues[0]) do |channel, delivery_info, props, payload|
        metadata = Queight::Metadata.new(channel, delivery_info, props)
        result << payload
        metadata.ack
      end
    end
    test_helper.wait_for_no_messages(queues[0])

    expect(result).to eq messages.map(&:last)
  end

  it "#publish_to_queue publishes via the default exchange" do
    queue_name = "test.queue.direct.via_default"
    queue = test_helper.queue(Queight.queue(queue_name))
    message = message(:foo => "bar")

    client.publish_to_queue!(message, queue)
    test_helper.wait_for_messages(queue)
    result = test_helper.messages_from(queue)

    expect(result).to eq [message]
  end

  it "#message_count reports on queue sizes" do
    queue_name = "test.queue.message_count"
    queue = test_helper.queue(Queight.queue(queue_name))

    expect(client.message_count(queue)).to eq 0

    client.publish_to_queue!(message(:foo => "bar"), queue)
    test_helper.wait_for_messages(queue)

    expect(client.message_count(queue)).to eq 1
  end

  it "#purge purges a queue" do
    queue_name = "test.queue.message_count"
    queue = test_helper.queue(Queight.queue(queue_name))

    expect(client.message_count(queue)).to eq 0

    5.times { client.publish_to_queue!(message(:foo => "bar"), queue) }
    test_helper.wait_for_messages(queue)

    expect(client.message_count(queue)).to eq 5

    client.purge(queue)

    expect(client.message_count(queue)).to eq 0
  end

  it "has cancellable consumers" do
    queue_name = "test.queue.cancellable_consumer"
    queue = test_helper.queue(Queight.queue(queue_name))
    message = message(:foo => "bar")

    client.publish_to_queue!(message, queue)
    test_helper.wait_for_messages(queue)

    initial_thread_count = Thread.list.size

    buf = []
    subscriber = client.subscribe_non_blocking(queue) \
      do |channel, delivery_info, props, payload|
        metadata = Queight::Metadata.new(channel, delivery_info, props)
        buf << payload
        metadata.ack
      end

    expect(Thread.list.size).to eq(initial_thread_count + 1)

    loop do
      break if buf.size == 1
      sleep 0.001
    end

    expect(buf).to eq [message]

    subscriber.cancel

    expect(Thread.list.size).to eq initial_thread_count
  end
end
