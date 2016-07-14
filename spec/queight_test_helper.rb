class QueightTestHelper
  def initialize(client)
    @client = client
  end

  def clear
    @test_queues = []
    @test_topics = []
  end

  def cleanup
    @test_queues.each do |queue|
      @client.delete_queue(queue)
    end
    @test_topics.each do |topic_config|
      @client.delete_exchange(topic_config)
    end
    Queight::GlobalConnectionCache.reset_cache!
  end

  def topic(name)
    @test_topics << name
    name
  end

  def queue(name)
    @test_queues << name
    name
  end

  def messages_from(*queues)
    queues.flat_map do |queue|
      messages_from_queue(queue)
    end
  end

  def messages_from_queue(queue)
    buf = []
    @client.with_channel do |ch|
      q = queue.queue(ch)
      until q.message_count == 0
        _, _, msg = q.pop
        buf << msg
      end
    end
    buf
  end

  def wait_for_messages(queue, timeout: 0.5)
    @client.with_channel do |ch|
      q = queue.queue(ch)
      start = Time.new
      while q.message_count < 1
        sleep 0.001
        raise "timeout" if (Time.new - start) > timeout
      end
    end
  end

  def wait_for_no_messages(queue, timeout: 0.5)
    @client.with_channel do |ch|
      q = queue.queue(ch)
      start = Time.new
      while q.message_count > 0
        sleep 0.001
        raise "timeout" if (Time.new - start) > timeout
      end
    end
  end
end
