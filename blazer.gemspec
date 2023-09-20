require_relative "lib/blazer/version"

Gem::Specification.new do |spec|
  spec.name          = "blazer"
  spec.version       = Blazer::VERSION
  spec.summary       = "Explore your data with SQL. Easily create charts and dashboards, and share them with your team."
  spec.homepage      = "https://github.com/ankane/blazer"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{app,config,lib,licenses}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 3"

  spec.add_dependency "railties", ">= 6.1"
  spec.add_dependency "activerecord", ">= 6.1"
  spec.add_dependency "chartkick", ">= 5"
  spec.add_dependency "safely_block", ">= 0.4"
end
