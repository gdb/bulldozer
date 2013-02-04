module Bulldozer::Repo
  class Filesystem < AbstractRepo
    attr_reader :path

    def initialize(basedir, path)
      super(basedir)
      @path = path
    end

    # TODO: maybe verify the files exist?
    def ensure_checkout
    end

    def checkout_path
      path
    end
  end
end
