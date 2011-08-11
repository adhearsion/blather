# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "blather/version"

Gem::Specification.new do |s|
  s.name        = "blather"
  s.version     = Blather::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jeff Smick"]
  s.email       = %q{sprsquish@gmail.com}
  s.homepage    = "http://github.com/sprsquish/blather"
  s.summary     = %q{Simpler XMPP built for speed}
  s.description = %q{An XMPP DSL for Ruby written on top of EventMachine and Nokogiri}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.rdoc_options = %w{--charset=UTF-8}
  s.extra_rdoc_files = %w{LICENSE README.md}

  s.add_dependency("eventmachine", ["~> 0.12.6"])
  s.add_dependency("nokogiri", ["~> 1.4.0"])
  s.add_dependency("niceogiri", [">= 0.0.4"])
  s.add_dependency("minitest", [">= 1.7.1"])
  s.add_dependency("activesupport", [">= 3.0.7"])

  s.add_development_dependency("minitest", ["~> 1.7.1"])
  s.add_development_dependency("mocha", ["~> 0.9.12"])
  s.add_development_dependency("bundler", ["~> 1.0.0"])
  s.add_development_dependency("rcov", ["~> 0.9.9"])
  s.add_development_dependency("yard", ["~> 0.6.1"])
  s.add_development_dependency("bluecloth", ["~> 2.1.0"])
  s.add_development_dependency("rake")
end
