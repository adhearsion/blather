# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin spec).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'bundler/gem_tasks'
require 'bundler/setup'

task :default => :spec
task :test => :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'yard'
YARD::Tags::Library.define_tag 'Blather handler', :handler, :with_name
YARD::Templates::Engine.register_template_path 'yard/templates'

YARD::Rake::YardocTask.new(:doc) do |t|
  t.options = ['--no-private', '-m', 'markdown', '-o', './doc/public/yard']
end
