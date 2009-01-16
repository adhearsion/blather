require 'echoe'
require 'hanna/rdoctask'

task :build => :extensions
task :extension => :build

ext = Config::CONFIG["DLEXT"]
task :extensions => ["lib/vendor/libxml/ext/libxml/libxml_ruby.#{ext}"]
file "lib/vendor/libxml/ext/libxml/libxml_ruby.#{ext}" =>
  ["lib/vendor/libxml/ext/libxml/Makefile"] + FileList["lib/vendor/libxml/ext/libxml/*.{c,h}"].to_a do |t|
  Dir.chdir("lib/vendor/libxml/ext/libxml") {
    sh "make"
    sh "cp libxml_ruby.#{ext} ../../../../"
  }
end

namespace :extensions do
  task :clean do
    Dir.chdir('lib') { sh "rm -f *.bundle" }
    Dir.chdir("lib/vendor/libxml/ext/libxml") do
      sh "rm -f Makefile"
      sh "rm -f *.{o,so,bundle,log}"
    end
  end
end

file "lib/vendor/libxml/ext/libxml/Makefile" => ["lib/vendor/libxml/ext/libxml/extconf.rb"] do
  command = ["ruby"] + $:.map{|dir| "-I#{File.expand_path dir}"} + ["extconf.rb"]
  Dir.chdir("lib/vendor/libxml/ext/libxml") { sh(*command) }
end

Echoe.new('blather') do |p|
  p.author = 'Jeff Smick'
  p.email = 'sprsquish@gmail.com'
  p.url = 'http://github.com/sprsquish/blather/tree/master'

  p.project = 'squishtech'
  p.summary = 'An evented XMPP library written on EventMachine and libxml-ruby'

  p.extensions = %w[lib/vendor/libxml/ext/libxml/extconf.rb]

  p.runtime_dependencies = ['eventmachine']
  p.rdoc_options += %w[-S -T hanna --main README.rdoc --exclude autotest --exclude vendor]

  p.test_pattern = 'spec/**/*_spec.rb'
  p.rcov_options = ['--exclude \/Library\/Ruby\/Gems,spec\/', '--xrefs']
end
