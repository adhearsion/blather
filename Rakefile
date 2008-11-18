require 'echoe'
require 'lib/blather'

Echoe.new('blather') do |p|
  p.version = Blather.version
  p.project = 'squishtech'
  p.author = 'Jeff Smick'
  p.summary = 'An evented XMPP library written on EventMachine and libxml-ruby'
  p.runtime_dependencies = %w[eventmachine libxml]
  p.retain_gemspec = true
end