# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "queight/version"

Gem::Specification.new do |spec|
  spec.name          = "queight"
  spec.version       = Queight::VERSION
  spec.authors       = ["Jonathon M. Abbott"]
  spec.email         = ["jma@dandaraga.net"]

  spec.summary       = "a lightweight wrapper around bunny"
  spec.description   = spec.summary
  spec.homepage      = "http://github.com/JonathonMA/queight"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "json", "< 2" if RUBY_VERSION < "1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop" if RUBY_VERSION >= "1.9"

  if RUBY_VERSION < "2.0"
    spec.add_dependency "bunny", "~> 1.7"
  else
    spec.add_dependency "bunny"
  end
  spec.add_dependency "connection_pool"
  spec.add_dependency "uri_config", "~> 0.0.11"
end
