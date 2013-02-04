require 'amqp'
require 'bunny'

module Bulldozer
  # TODO: it's a biiit weird to have this combined
  # blocking/nonblocking setup, since the APIs are slightly different
  # in both cases.
  module RabbitMQ
    def self.bunny
      @bunny
    end

    def self.channel
      @channel
    end

    def self.job_queue
      @job_queue
    end

    def self.result_queue
      @result_queue
    end

    JOB_QUEUE_NAME = 'bulldozer-job'
    RESULT_QUEUE_NAME = 'bulldozer-result'

    def self.connect_async(host='localhost')
      @connection = AMQP.connect(:host => host)
      @channel = AMQP::Channel.new(@connection)
      @exchange = @channel.default_exchange
      @job_queue = @channel.queue(JOB_QUEUE_NAME)
      @result_queue = @channel.queue(RESULT_QUEUE_NAME)
    end

    def self.connect_sync(host='localhost')
      @bunny = Bunny.new(:host => host,
        :threaded => false,
        :heartbeat => 0,
        :socket_timeout => 0,
        :connect_timeout => 0)
      @bunny.start

      @channel = @bunny.create_channel
      @exchange = @channel.exchange('')
      @job_queue = @channel.queue(JOB_QUEUE_NAME)
      @result_queue = @channel.queue(RESULT_QUEUE_NAME)
    end

    def self.publish_structured(queue, job)
      generated = Bulldozer::SERIALIZER.dump(job)
      @exchange.publish(generated, :routing_key => queue)
    end

    def self.ack(delivery_tag)
      @channel.acknowledge(delivery_tag, false)
    end
  end
end
