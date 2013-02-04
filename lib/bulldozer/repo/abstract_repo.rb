module Bulldozer::Repo
  class AbstractRepo
    attr_reader :basedir

    def initialize(basedir)
      @basedir = basedir
    end

    def ensure_checkout
      raise NotImplementedError.new('Override in subclass')
    end

    def checkout_path
      raise NotImplementedError.new('Override in subclass')
    end

    def entry_point
      raise NotImplementedError.new('Override in subclass')
    end
  end
end
