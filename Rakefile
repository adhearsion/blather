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
    gem.add_dependency 'nokogiri', '>= 1.3.0'

    gem.files = FileList['examples/**/*', 'lib/**/*'].to_a

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

begin
  require 'rake/contrib/sshpublisher'
  namespace :rubyforge do
    
    desc "Release gem and RDoc documentation to RubyForge"
    task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]
    
    namespace :release do
      desc "Publish RDoc to RubyForge."
      task :docs => [:rdoc] do
        config = YAML.load(
            File.read(File.expand_path('~/.rubyforge/user-config.yml'))
        )

        host = "#{config['username']}@rubyforge.org"
        remote_dir = "/var/www/gforge-projects/squishtech/blather"
        local_dir = 'rdoc'

        Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
      end
    end
  end
rescue LoadError
  puts "Rake SshDirPublisher is unavailable or your rubyforge environment is not configured."
end

task :default => :test
