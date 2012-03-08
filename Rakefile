require 'rubygems'
require 'rake'

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'spec'
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

  require 'yard'
  YARD::Tags::Library.define_tag 'Blather handler', :handler, :with_name
  YARD::Templates::Engine.register_template_path 'yard/templates'

  YARD::Rake::YardocTask.new(:doc) do |t|
    t.options = ['--no-private', '-m', 'markdown', '-o', './doc/public/yard']
  end
rescue LoadError
end

task :default => :test

def system!(cmd)
  puts cmd
  raise "Command failed!" unless system(cmd)
end

namespace :ci do

  desc "For current RVM, run the tests for one gemfile"
  task :run_one, :gemfile do |t, args|
    ENV['BUNDLE_GEMFILE'] = File.expand_path(args[:gemfile] || (File.dirname(__FILE__) + '/spec/gemfiles/Gemfile.nokogiri-1.4.7'))
    system! 'bundle install && bundle exec rake'
  end

  desc "For current RVM, run the tests for all gemfiles described in travis.yml"
  task :run_all do
    config = YAML.load_file('.travis.yml')
    config['gemfile'].each do |gemfile|
      print [gemfile].inspect.ljust(40) + ": "
      cmd = "rake \"ci:run_one[#{gemfile}]\""
      result = system "#{cmd} > /dev/null 2>&1"
      result = result ? "OK" : "FAILED! - re-run with: #{cmd}"
      puts result
    end
  end

end