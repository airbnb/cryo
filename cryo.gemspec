# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cryo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nathan Baxter"]
  gem.email         = ["nathan.baxter@airbnb.com"]
  gem.summary       = %q{Tool for snapshotting data, backing it up, verifying it, and cycling it.}
  gem.homepage      = "https://github.com/airbnb/cryo"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "cryo"
  gem.require_paths = ["lib"]
  gem.version       = Cryo::VERSION
end
