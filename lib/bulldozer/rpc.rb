require 'set'

require 'rubysh'
require 'bulldozer/third/class_utils'

module Bulldozer
  module RPC
    @repo_spec = nil

    def self.included(other)
      other.extend(ClassMethods)
    end

    def self.use_filesystem_repo(path)
      @repo_spec = repo_spec_filesystem(path)
    end

    def self.use_git_repo(path)
      @repo_spec = repo_spec_git(path)
    end

    def self.repo_spec
      @repo_spec
    end

    private

    def self.repo_spec_git(file)
      remote = git_remote(file)
      commit = git_commit(file)
      {
        'type' => 'git',
        'remote' => remote,
        'commit' => commit
      }
    end

    def self.repo_spec_filesystem(file)
      {
        'type' => 'filesystem',
        'path' => file
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
      def defer(name, *arguments)
        repo = Bulldozer::RPC.repo_spec
        raise "Must set the repo spec to define where workers get their code from. If you're just playing around, try something like: Bulldozer::RPC.use_filesystem_repo(File.join(__FILE__, '../..'))" unless repo

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
        Bulldozer::Third::ClassUtils.define_object_method(self, name, blk)
        bulldozer_rpcs << name.to_s
      end

      def invoke_rpc(name, *arguments)
        raise "No such RPC on #{self}: #{name}" unless bulldozer_rpcs.include?(name)
        send(name, *arguments)
      end

      def bulldozer_rpcs
        @bulldozer_rpcs ||= Set.new
      end
    end
  end
end
