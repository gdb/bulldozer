require 'logger'
require 'msgpack'

require 'bulldozer/rabbitmq'
require 'bulldozer/repo'
require 'bulldozer/rpc'
require 'bulldozer/version'
require 'bulldozer/worker_pool'

module Bulldozer
  def self.log
    unless @log
      @log = Logger.new(STDERR)
      @log.level = Logger::DEBUG
    end

    @log
  end

  class SERIALIZER
    def self.load(data)
      MessagePack.unpack(data)
    end

    def self.dump(data)
      MessagePack.pack(data)
    end
  end
end
