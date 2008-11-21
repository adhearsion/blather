# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.rubyforge_project = 'squishtech'

  s.name = 'blather'
  s.description = 'An evented XMPP library written on EventMachine and libxml-ruby'
  s.summary = 'Evented XMPP library'
  s.version = '0.1'
  s.date = '2008-11-17'

  s.authors = ['Jeff Smick']
  s.email = 'jeff.smick@squishtech.com'

  s.files = %w[
    README.rdoc
    CHANGELOG
    blather.gemspec
    examples/echo.rb
    examples/shell_client.rb
    lib/blather/callback.rb
    lib/blather/client.rb
    lib/blather/core/errors.rb
    lib/blather/core/jid.rb
    lib/blather/core/roster.rb
    lib/blather/core/roster_item.rb
    lib/blather/core/stanza.rb
    lib/blather/core/stanzas/error.rb
    lib/blather/core/stanzas/iq.rb
    lib/blather/core/stanzas/iqs/queries/roster.rb
    lib/blather/core/stanzas/iqs/query.rb
    lib/blather/core/stanzas/message.rb
    lib/blather/core/stanzas/presence.rb
    lib/blather/core/stanzas/presences/status.rb
    lib/blather/core/stanzas/presences/subscription.rb
    lib/blather/core/stream.rb
    lib/blather/core/streams/parser.rb
    lib/blather/core/streams/resource.rb
    lib/blather/core/streams/sasl.rb
    lib/blather/core/streams/session.rb
    lib/blather/core/streams/tls.rb
    lib/blather/core/sugar.rb
    lib/blather/core/xmpp_node.rb
    lib/blather/extensions/last_activity.rb
    lib/blather/extensions/version.rb
    lib/blather.rb
    LICENSE
  ]

  s.test_files = %w[
    lib/autotest/discover.rb
    lib/autotest/spec.rb
    spec/blather/core/jid_spec.rb
    spec/blather/core/roster_item_spec.rb
    spec/blather/core/roster_spec.rb
    spec/blather/core/stanza_spec.rb
    spec/blather/core/stream_spec.rb
    spec/blather/core/xmpp_node_spec.rb
    spec/spec_helper.rb
  ]

  s.extra_rdoc_files = %w[
    README.rdoc
    CHANGELOG
    LICENSE
  ]

  s.has_rdoc = true
  s.rdoc_options = %w[--line-numbers --inline-source --title Blather --main README]

  s.add_dependency('eventmachine', ['> 0.0.0'])
  s.add_dependency('libxml', ['> 0.0.0'])
end
