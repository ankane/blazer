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

  spec.required_ruby_version = ">= 2.4"

  rails_version = ">= 5"
  spec.add_dependency "railties", rails_version
  spec.add_dependency "activerecord", rails_version
  spec.add_dependency "actionpack", rails_version # actioncontroller
  spec.add_dependency "activejob", rails_version
  spec.add_dependency "actionmailer", rails_version
  spec.add_dependency "chartkick", ">= 3.2"
  spec.add_dependency "safely_block", ">= 0.1.1"
end
