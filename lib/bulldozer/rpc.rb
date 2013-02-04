require 'rubysh'

module Bulldozer
  module RPC
    def self.included(other)
      other.extend(ClassMethods)
    end

    def self.discover_repo(file)
      remote = git_remote(file)
      commit = git_commit(file)
      {
        'type' => 'git',
        'remote' => remote,
        'commit' => commit
      }
    end

    def self.git_remote(file)
      dir = File.dirname(file)
      runner = Rubysh('git', 'remote', '-v', Rubysh.>(:stdout), :cwd => dir).check_call
      stdout = runner.read(:stdout)

      remote = nil
      # Could do this with ^...$, but I prefer to avoid those altogether.
      stdout.split("\n").each do |line|
        next unless line =~ /\Aorigin\t(.*) \(fetch\)\z/
        remote = $1
      end

      raise "No git remote configured" unless remote

      remote
    end

    def self.git_commit(file)
      dir = File.dirname(file)
      runner = Rubysh('git', 'rev-parse', 'HEAD', Rubysh.>(:stdout), :cwd => dir).check_call
      stdout = runner.read(:stdout).strip
      stdout
    end

    module ClassMethods
      def repo(location)
        @bulldozer_repo = location
      end

      def defer(name, *arguments)
        # TODO: cache? make sure it matches the running version? have
        # a DSL for specifying?
        # repo = Bulldozer::RPC.discover_repo(@bulldozer_repo)

        # Make this configurable
        repo = {
          'type' => 'filesystem',
          'path' => File.expand_path('../..', File.dirname(__FILE__))
        }

        job = {
            'class' => self.name,
            'method' => name,
            'arguments' => arguments
        }

        Bulldozer::RabbitMQ.publish_structured(
          Bulldozer::RabbitMQ::JOB_QUEUE_NAME,
          'repo' => repo,
          'entry_point' => 'example/printer.rb',
          'job' => job
          )
      end

      def rpc(name, &blk)
        rpcs[name.to_s] = blk
      end

      def invoke_rpc(name, *arguments)
        raise "No such RPC on #{self}: #{name}" unless rpc = rpcs[name]
        # TODO: maybe run as a bound method?
        rpc.call(*arguments)
      end

      def rpcs
        @bulldozer_rpcs ||= {}
      end
    end
  end
end
