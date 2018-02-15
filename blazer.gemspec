# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "blazer/version"

Gem::Specification.new do |spec|
  spec.name          = "blazer"
  spec.version       = Blazer::VERSION
  spec.authors       = ["Andrew Kane"]
  spec.email         = ["andrew@chartkick.com"]
  spec.summary       = "Explore your data with SQL. Easily create charts and dashboards, and share them with your team."
  spec.homepage      = "https://github.com/ankane/blazer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 4"
  spec.add_dependency "activerecord", ">= 4"
  spec.add_dependency "chartkick"
  spec.add_dependency "safely_block", ">= 0.1.1"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
