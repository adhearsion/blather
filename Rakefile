require 'rubygems'
require 'rake'

require 'bundler'
Bundler::GemHelper.install_tasks

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
