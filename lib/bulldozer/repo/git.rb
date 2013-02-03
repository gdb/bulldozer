require 'fileutils'

module Bulldozer::Repo
  # TODO: better cleanup on failures
  class Git
    attr_reader :basedir, :remote, :commit

    def initialize(basedir, remote, commit)
      @basedir = basedir
      @remote = remote
      @commit = commit
    end

    def ensure_checkout
      if File.exists?(commit_path)
        Bulldozer.log.debug("Skipping checkout of #{commit} in #{remote} since #{commit_path} exists")
        return false
      end

      ensure_commit
      checkout

      true
    end

    private

    def ensure_commit
      just_cloned = ensure_clone
      return if has_commit?
      fetch if !just_cloned
      raise "Invalid commit: #{commit}" unless has_commit?
    end

    def ensure_clone
      if File.exists?(clone_path)
        Bulldozer.log.debug("Skipping clone of #{remote} since clone exists")
        return false
      end

      clone
      true
    end

    def clone
      cmd = Rubysh('git', 'clone', '--bare', remote, clone_path)
      Bulldozer.log.info("Running #{cmd}")
      cmd.check_call
    end

    def checkout
      FileUtils.mkdir(commit_path)
      begin
        # TODO: implement pipestatus in Rubysh
        cmd = Rubysh('git', 'archive', commit, :cwd => clone_path) | Rubysh('tar', 'x', '-C', commit_path)
        Bulldozer.log.info("Running #{cmd}")
        cmd.check_call
      rescue Exception => e
        FileUtils.rm_rf(commit_path)
        raise
      end
    end

    def fetch
      cmd = Rubysh('git', 'fetch', :cwd => clone_path)
      Bulldozer.log.info("Running #{cmd}")
      cmd.check_call
    end

    def has_commit?
      runner = Rubysh('git', 'cat-file', '-t', commit, Rubysh.>('/dev/null'), :cwd => clone_path).run
      runner.full_status.success?
    end

    def clone_path
      @clone_path ||= File.join(basedir, remote.gsub('/', '--'))
    end

    def commit_path
      @commit_path ||= File.join(basedir, commit)
    end
  end
end
