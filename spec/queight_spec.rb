require "spec_helper"

require "queight"
require "thread"

def exercise(client, exchange, queues, messages)
  queues.each do |queue|
    client.bind(exchange, queue)
  end

  messages.each do |routing_key, message|
    client.publish(exchange, message, routing_key)
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

    exercise(client, exchange, queues, messages)
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

    exercise(client, exchange, queues, messages)
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
      test_helper.queue(Queight.queue("test.queue1", :routing => routing_keys)),
    ]

    exercise(client, exchange, queues, messages)

    result = test_helper.messages_from(*queues)

    expect(result).to eq messages.map(&:last)
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
end
