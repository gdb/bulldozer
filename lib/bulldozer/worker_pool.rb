require 'securerandom'

module Bulldozer
  # TODO: full worker management
  class WorkerPool
    attr_reader :pool_size, :repo, :entry_point, :queue

    def initialize(repo, entry_point)
      @repo = repo
      @pool_size = 1
      @entry_point = entry_point

      create_queue
    end

    def create_queue
      # TODO: anything to worry about, re: this not being synchronous?
      @queue = "bulldozer-worker-#{SecureRandom.random_number * 100000000}"
      # Would be nice to force deletion
      Bulldozer::RabbitMQ.channel.queue(@queue,
        :auto_delete => true)
    end

    def transmit(job)
      Bulldozer::RabbitMQ.publish_structured(@queue, job)
    end

    def spawn
      @workers = (1..pool_size).map do |worker|
        cmd = Rubysh('bundle', 'exec', 'dozer', '-q', queue, '--', entry_point, :cwd => repo.checkout_path)
        Bulldozer.log.info("Spawning worker #{cmd}")
        cmd.run_async # TODO: handle crashes
      end

      at_exit do
        @workers.each do |worker|
          pid = worker.pid
          begin
            Process.kill('TERM', pid)
          rescue Errno::ESRCH
            Bulldozer.log.info("Worker #{pid} has already exited")
          else
            Bulldozer.log.debug("Sent TERM to #{pid} successfully")
          end
        end
      end
    end
  end
end
