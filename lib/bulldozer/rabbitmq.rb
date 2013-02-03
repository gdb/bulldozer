require 'amqp'
require 'bunny'
require 'json'

module Bulldozer
  module RabbitMQ
    attr_reader :job_queue, :result_queue

    JOB_QUEUE_NAME = 'bulldozer-job'
    RESULT_QUEUE_NAME = 'bulldozer-result'

    def self.connect_async
      @connection = AMQP.connect(:host => 'localhost')
      @channel = AMQP::Channel.new(@connection)
      @exchange = @channel.default_exchange
      @job_queue = @channel.queue(JOB_QUEUE_NAME)
      @result_queue = @channel.queue(RESULT_QUEUE_NAME)
    end

    def self.connect_sync
      @bunny = Bunny.new(:host => 'localhost')
      @bunny.start

      @channel = @bunny.create_channel
      @exchange = @channel.exchange('')
      @job_queue = @channel.queue(JOB_QUEUE_NAME)
      @result_queue = @channel.queue(RESULT_QUEUE_NAME)
    end

    def self.publish_job(job)
      generated = JSON.pretty_generate(job)
      @exchange.publish(generated, :routing_key => JOB_QUEUE_NAME)
    end

    def self.publish_result(result)
      generated = JSON.pretty_generate(result)
      @exchange.publish(generated, :routing_key => RESULT_QUEUE_NAME)
    end

    def self.ack(delivery_tag)
      @channel.acknowledge(delivery_tag, false)
    end
  end
end
