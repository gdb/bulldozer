require 'securerandom'

module Bulldozer
  # TODO: full worker management
  class WorkerPool
    attr_reader :pool_size, :repo, :queue

    def self.scrub_env
      return if @scrub_env
      @scrub_env = true

      # TODO: implement env scrubbing in Rubysh
      ENV.keys.select {|key| key =~ /\ABUNDLE/}.each {|key| ENV.delete(key)}
    end

    def initialize(repo)
      @repo = repo
      @pool_size = 1
      @workers = {}

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

    def spawn_worker
      cmd = Rubysh('bundle', 'exec', 'dozer', '-q', queue, '--', repo.entry_point, :cwd => repo.checkout_path)
      runner = cmd.run_async # TODO: handle crashes
      Bulldozer.log.info("Spawning worker #{runner}")
      @workers[runner.pid] = runner
      runner
    end

    def spawn
      pool_size.times {spawn_worker}

      at_exit do
        @workers.each do |pid, _|
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
