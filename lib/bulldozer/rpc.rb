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
      entry_point = git_entrypoint(file)
      remote = git_remote(file)
      commit = git_commit(file)
      {
        'type' => 'git',
        'remote' => remote,
        'commit' => commit,
        'entry_point' => entry_point
      }
    end

    def self.repo_spec_filesystem(file)
      {
        'type' => 'filesystem',
        'path' => File.expand_path(file)
      }
    end

    def self.git_entrypoint(file)
      file = File.expand_path(file)
      runner = Rubysh('git', 'rev-parse', '--show-toplevel', Rubysh.>(:stdout),
        :cwd => File.dirname(file)).run
      basedir = runner.read(:stdout).strip
      Bulldozer.log.debug("Discovered git toplevel directory #{basedir}")

      # Very janky. Should fixup.
      prefix = file[0...basedir.length]
      slash = file[basedir.length..basedir.length]
      rest = file[basedir.length+1..-1]
      raise "Not sure how to handle: basedir is #{basedir} but is not the prefix of file #{file}. Corresponding prefix: #{prefix}" unless basedir == prefix
      raise "Not sure how to handle: after the prefix of #{basedir} is not a slash: #{file}" unless slash == '/'
      rest
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
