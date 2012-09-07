# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cryo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nathan Baxter"]
  gem.email         = ["nathan.baxter@airbnb.com"]
  gem.summary       = %q{Tool for snapshotting data, backing it up, verifying it, cycling it, and triggering notifications.}
  gem.homepage      = "https://github.com/airbnb/cryo"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = ["cryo"]

  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "cryo"
  gem.require_paths = ["lib"]
  gem.version       = Cryo::VERSION

  gem.add_runtime_dependency "colorize"
  gem.add_runtime_dependency "thor", "~> 0.15"
  gem.add_runtime_dependency "aws-sdk", '~> 1.6'
  gem.add_development_dependency "pry"
end
