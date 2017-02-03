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

  spec.files         = Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir["test/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails"
  spec.add_dependency "chartkick"
  spec.add_dependency "safely_block", ">= 0.1.1"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"

  # DB Adapters for testing
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "tiny_tds"
  spec.add_development_dependency "activerecord-sqlserver-adapter"

end
