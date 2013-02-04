require 'fileutils'

module Bulldozer::Repo
  class Git < AbstractRepo
    attr_reader :entry_point, :remote, :commit

    def initialize(basedir, entry_point, remote, commit)
      super(basedir)
      @entry_point = entry_point
      @remote = remote
      @commit = commit
    end

    def ensure_checkout
      # TODO: better cleanup on failures (maybe touch a file on success?)
      if File.exists?(commit_path)
        Bulldozer.log.debug("Skipping checkout of #{commit} in #{remote} since #{commit_path} exists")
        return false
      end

      begin
        ensure_commit
        checkout
        bundle
      rescue Exception => e
        FileUtils.rm_rf(commit_path)
        raise
      end

      true
    end

    def checkout_path
      commit_path
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

    def bundle
      cmd = Rubysh('bundle', 'install', '--path', bundle_path, :cwd => commit_path)
      Bulldozer.log.info("Running #{cmd}")
      cmd.check_call
    end

    def clone
      cmd = Rubysh('git', 'clone', '--bare', remote, clone_path)
      Bulldozer.log.info("Running #{cmd}")
      cmd.check_call
    end

    def checkout
      FileUtils.mkdir(commit_path)
      # TODO: implement pipestatus in Rubysh
      cmd = Rubysh('git', 'archive', commit, :cwd => clone_path) | Rubysh('tar', 'x', '-C', commit_path)
      Bulldozer.log.info("Running #{cmd}")
      cmd.check_call
    end

    def fetch
      cmd = Rubysh('git', 'fetch', 'origin', '+refs/heads/*:refs/heads/*', :cwd => clone_path)
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

    def bundle_path
      @bundle_path ||= File.join(basedir, 'vendor/bundle')
    end
  end
end
