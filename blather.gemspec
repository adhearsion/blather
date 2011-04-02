# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "blather/version"

Gem::Specification.new do |s|
  s.name        = "blather"
  s.version     = Blather::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jeff Smick"]
  s.email       = %q{sprsquish@gmail.com}
  s.date        = %q{2010-09-02}
  s.homepage    = "http://github.com/sprsquish/blather"
  s.summary     = %q{Simpler XMPP built for speed}
  s.description = %q{An XMPP DSL for Ruby written on top of EventMachine and Nokogiri}

  s.rubyforge_project = "squishtech"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.rdoc_options = %w{--charset=UTF-8}
  s.extra_rdoc_files = %w{LICENSE README.md}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.6"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.4.0"])
      s.add_development_dependency(%q<minitest>, [">= 1.7.1"])
      s.add_development_dependency(%q<mocha>)
      s.add_development_dependency(%q<rake>)
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.6"])
      s.add_dependency(%q<nokogiri>, [">= 1.4.0"])
      s.add_dependency(%q<minitest>, [">= 1.7.1"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.6"])
    s.add_dependency(%q<nokogiri>, [">= 1.4.0"])
    s.add_dependency(%q<minitest>, [">= 1.7.1"])
  end
end
