require 'echoe'

begin
  require 'hanna'
rescue LoadError
end

desc 'Build extensions'
task :build => :extensions
task :extension => :build

ext = Config::CONFIG["DLEXT"]
task :extensions => ["ext/push_parser.#{ext}"]
file "ext/push_parser.#{ext}" =>
  ["Makefile"] + FileList["ext/*.{c,h}"].to_a do |t|
  Dir.chdir("ext") { sh "make" }
end

namespace :extensions do
  desc 'Clean extensions'
  task :clean do
    Dir.chdir("ext") do
      sh "rm -f Makefile"
      sh "rm -f *.{o,so,bundle,log}"
    end
  end
end

file "Makefile" => %w[ext/extconf.rb] do
  command = ["ruby"] + $:.map{|dir| "-I#{File.expand_path dir}"} + ["extconf.rb"]
  Dir.chdir("ext") { sh(*command) }
end


Echoe.new('blather') do |p|
  p.author = 'Jeff Smick'
  p.email = 'sprsquish@gmail.com'
  p.url = 'http://github.com/sprsquish/blather/tree/master'

  p.extensions = %w[ext/extconf.rb]

  p.project = 'squishtech'
  p.summary = 'An evented XMPP library written on EventMachine and libxml-ruby'

  p.runtime_dependencies = ['eventmachine']
  p.rdoc_options += %w[-S -T hanna --main README.rdoc --exclude autotest --exclude vendor]

  p.test_pattern = 'spec/**/*_spec.rb'
  p.rcov_options = ['--exclude \/Library\/Ruby\/Gems,spec\/', '--xrefs']
end
