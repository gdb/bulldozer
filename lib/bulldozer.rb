require 'logger'

require 'bulldozer/rabbitmq'
require 'bulldozer/repo'
require 'bulldozer/rpc'
require 'bulldozer/version'

module Bulldozer
  def self.log
    unless @log
      @log = Logger.new(STDERR)
      @log.level = Logger::DEBUG
    end

    @log
  end
end
