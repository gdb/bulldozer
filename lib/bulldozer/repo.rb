require 'bulldozer/repo/abstract_repo'

require 'bulldozer/repo/filesystem'
require 'bulldozer/repo/git'

module Bulldozer
  module Repo
    def self.from_spec(repo, basedir)
      case type = repo['type']
      when 'git'
        remote = repo['remote']
        commit = repo['commit']

        Bulldozer::Repo::Git.new(basedir, remote, commit)
      when 'filesystem'
        path = repo['path']

        Bulldozer::Repo::Filesystem.new(basedir, path)
      else
        raise "Invalid repo type #{type.inspect}"
      end
    end
  end
end
