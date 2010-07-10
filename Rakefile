require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'blather'
    gem.summary = 'Simpler XMPP built for speed'
    gem.description = 'An XMPP DSL for Ruby written on top of EventMachine and Nokogiri'

    gem.email = 'sprsquish@gmail.com'
    gem.homepage = 'http://github.com/sprsquish/blather'
    gem.authors = ['Jeff Smick']

    gem.rubyforge_project = 'squishtech'

    gem.add_dependency 'eventmachine', '>= 0.12.6'
    gem.add_dependency 'nokogiri', '>= 1.4.0'

    gem.files = FileList['examples/**/*.rb', 'lib/**/*.rb'].to_a

    gem.test_files = FileList['spec/**/*.rb']

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'spec'
  test.pattern = 'spec/**/*_spec.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'spec'
    test.pattern = 'spec/**/*_spec.rb'
    test.rcov_opts += ['--exclude \/Library\/Ruby,spec\/', '--xrefs']
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end


begin
  require 'yard'
  YARD::Tags::Library.define_tag 'Blather handler', :handler, :with_name
  YARD::Templates::Engine.register_template_path 'yard/templates'

  YARD::Rake::YardocTask.new do |t|
    t.options = ['--no-private', '-m', 'markdown', '-o', './doc/public/yard']
  end
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end

desc 'Generate documentation'
task :doc => :yard
task :default => :test
