# frozen_string_literal: true

require "./lib/minitest/utils/version"

Gem::Specification.new do |spec|
  spec.name          = "minitest-utils"
  spec.version       = Minitest::Utils::VERSION
  spec.authors       = ["Nando Vieira"]
  spec.email         = ["fnando.vieira@gmail.com"]
  spec.summary       = "Some utilities for your Minitest day-to-day usage."
  spec.description   = spec.summary
  spec.homepage      = "http://github.com/fnando/minitest-utils"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.3.0")

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject {|f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "listen"
  spec.add_dependency "minitest"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-fnando"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "test_notifier"
  spec.metadata["rubygems_mfa_required"] = "true"
end
