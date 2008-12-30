require 'echoe'
require 'hanna/rdoctask'

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