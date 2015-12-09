# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'minitest/tagz/version'

Gem::Specification.new do |spec|
  spec.name          = "minitest-tagz"
  spec.version       = Minitest::Tagz::VERSION
  spec.authors       = ["Josh Bodah"]
  spec.email         = ["jb3689@yahoo.com"]

  spec.summary       = %q{yet another tags implementation for Minitest}
  spec.description   = %q{allows you to tag different Minitest tests with tags that can be used to filter tests}
  spec.homepage      = "https://github.com/backupify/minitest-tagz"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "minitest", "~> 5"
  spec.add_dependency "shoulda-context"
  spec.add_dependency 'state_machine'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency 'pry-byebug'
end
