#!/usr/bin/env ruby
require 'logger'
require 'optparse'

require 'bulldozer'

$log = Logger.new(STDOUT)
$log.level = Logger::WARN

module Bulldozer
  Bulldozer::RPC.use_git_repo(__FILE__)

  class Printer
    include Bulldozer::RPC

    rpc(:print) do |argument|
      p argument
    end
  end
end

def main
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] [msg]"

    opts.on('-h', '--help', 'Display this message') do
      puts opts
      exit(1)
    end
  end
  optparse.parse!

  if ARGV.length == 0
    EM.run do
      Bulldozer::RabbitMQ.connect_async
      Bulldozer.run_worker
    end
  elsif ARGV.length == 1
    Bulldozer::RabbitMQ.connect_sync
    Bulldozer::Printer.defer(:print, ARGV[0])
  else
    puts optparse
    return 1
  end

  return 0
end

if $0 == __FILE__
  ret = main
  begin
    exit(ret)
  rescue TypeError
    exit(0)
  end
end
