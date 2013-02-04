# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bulldozer/version'

Gem::Specification.new do |gem|
  gem.name          = "bulldozer"
  gem.version       = Bulldozer::VERSION
  gem.authors       = ["Greg Brockman"]
  gem.email         = ["gdb@gregbrockman.com"]
  gem.description   = %q{A distributed, version-aware job running framework}
  gem.summary       = %q{Bulldozer makes it easy to run jobs across pools of workers.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "amqp"
  gem.add_dependency "msgpack"
end
