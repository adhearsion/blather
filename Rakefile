require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = 'blather'
  gem.summary = 'Simpler XMPP built for speed'
  gem.description = 'An XMPP DSL for Ruby written on top of EventMachine and Nokogiri'

  gem.email = 'sprsquish@gmail.com'
  gem.homepage = 'http://github.com/sprsquish/blather'
  gem.authors = ['Jeff Smick']
  gem.license = "MIT"

  gem.add_dependency 'eventmachine', '~> 0.12.6'
  gem.add_dependency 'nokogiri', '~> 1.4.0'

  gem.add_development_dependency 'minitest', '~> 1.7.1'
  gem.add_development_dependency 'mocha', '~> 0.9.12'
  gem.add_development_dependency 'yard', '~> 0.6.0'
  gem.add_development_dependency 'bundler', '~> 1.0.0'
  gem.add_development_dependency 'jeweler', '~> 1.5.2'
  gem.add_development_dependency 'rcov', '~> 0.9.9'

  gem.files = FileList['examples/**/*.rb', 'lib/**/*.rb'].to_a

  gem.test_files = FileList['spec/**/*.rb']
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'spec'
  test.pattern = 'spec/**/*_spec.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'spec'
  test.pattern = 'spec/**/*_spec.rb'
  test.rcov_opts += ['--exclude \/Library\/Ruby,spec\/', '--xrefs']
  test.verbose = true
end

require 'yard'
YARD::Tags::Library.define_tag 'Blather handler', :handler, :with_name
YARD::Templates::Engine.register_template_path 'yard/templates'

YARD::Rake::YardocTask.new do |t|
  t.options = ['--no-private', '-m', 'markdown', '-o', './doc/public/yard']
end

desc 'Generate documentation'
task :doc => :yard
task :default => :test
