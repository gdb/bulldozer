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
        entry_point = repo.fetch('entry_point')

        Bulldozer::Repo::Git.new(basedir, entry_point, remote, commit)
      when 'filesystem'
        path = repo['path']

        Bulldozer::Repo::Filesystem.new(basedir, path)
      else
        raise "Invalid repo type #{type.inspect}"
      end
    end
  end
end
