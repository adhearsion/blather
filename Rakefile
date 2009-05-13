require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'blather'
    gem.summary = 'An evented XMPP library written on EventMachine and libxml-ruby'

    gem.email = 'sprsquish@gmail.com'
    gem.homepage = 'http://github.com/sprsquish/blather'
    gem.authors = ['Jeff Smick']

    gem.rubyforge_project = 'squishtech'

    gem.extensions = ['Rakefile']

    gem.add_dependency 'eventmachine', '>= 0.12.6'
    gem.add_dependency 'libxml-ruby', '>= 1.1.2'

    gem.files = FileList['examples/**/*', 'lib/**/*', 'ext/*.{rb,c}'].to_a

    gem.test_files = FileList['spec/**/*.rb']

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
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
    test.rcov_opts += ['--exclude \/Library\/Ruby\/Gems,spec\/', '--xrefs']
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end


begin
  require 'hanna/rdoctask'

  Rake::RDocTask.new do |rdoc|
    if File.exist?('VERSION.yml')
      config = YAML.load(File.read('VERSION.yml'))
      version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
    else
      version = ""
    end

    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "blather #{version}"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.options += %w[-S -T hanna --main README.rdoc --exclude autotest --exclude vendor]
  end
rescue LoadError
  task :rdoc do
    abort "Hanna is not available. In order to use the Hanna, you must: sudo gem install mislav-hanna"
  end
end

MAKE = ENV['MAKE'] || (RUBY_PLATFORM =~ /mswin/ ? 'nmake' : 'make')

namespace :ext do
  ext_sources = FileList['ext/*.{rb,c}']

  desc 'Compile the makefile'
  file 'ext/Makefile' => ext_sources do
    chdir('ext') { ruby 'extconf.rb' }
  end

  desc "make extension"
  task :make => ext_sources + ['ext/Makefile'] do
    chdir('ext') { sh MAKE }
  end

  desc 'Build push parser'
  task :build => :make

  desc 'Clean extensions'
  task :clean do
    chdir 'ext' do
      sh "rm -f Makefile"
      sh "rm -f *.{o,so,bundle,log}"
    end
  end
end

# If running under rubygems...
__DIR__ ||= File.expand_path(File.dirname(__FILE__))
if Gem.path.any? {|path| %r(^#{Regexp.escape path}) =~ __DIR__}
  task :default => :gem_build
else
  task :default => ['ext:build', :test]
end
 
desc ":default build when running under rubygems."
task :gem_build => 'ext:build'
