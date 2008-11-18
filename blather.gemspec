# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{blather}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeff Smick"]
  s.date = %q{2008-11-17}
  s.description = %q{An evented XMPP library written on EventMachine and libxml-ruby}
  s.email = %q{}
  s.extra_rdoc_files = ["CHANGELOG", "lib/autotest/discover.rb", "lib/autotest/spec.rb", "lib/blather/callback.rb", "lib/blather/client.rb", "lib/blather/core/errors.rb", "lib/blather/core/jid.rb", "lib/blather/core/roster.rb", "lib/blather/core/roster_item.rb", "lib/blather/core/stanza.rb", "lib/blather/core/stanzas/error.rb", "lib/blather/core/stanzas/iq.rb", "lib/blather/core/stanzas/iqs/queries/roster.rb", "lib/blather/core/stanzas/iqs/query.rb", "lib/blather/core/stanzas/message.rb", "lib/blather/core/stanzas/presence.rb", "lib/blather/core/stanzas/presences/status.rb", "lib/blather/core/stanzas/presences/subscription.rb", "lib/blather/core/stream.rb", "lib/blather/core/streams/parser.rb", "lib/blather/core/streams/resource.rb", "lib/blather/core/streams/sasl.rb", "lib/blather/core/streams/session.rb", "lib/blather/core/streams/tls.rb", "lib/blather/core/sugar.rb", "lib/blather/core/xmpp_node.rb", "lib/blather/extensions/last_activity.rb", "lib/blather/extensions/version.rb", "lib/blather.rb", "LICENSE", "README"]
  s.files = ["CHANGELOG", "examples/echo.rb", "examples/shell_client.rb", "lib/autotest/discover.rb", "lib/autotest/spec.rb", "lib/blather/callback.rb", "lib/blather/client.rb", "lib/blather/core/errors.rb", "lib/blather/core/jid.rb", "lib/blather/core/roster.rb", "lib/blather/core/roster_item.rb", "lib/blather/core/stanza.rb", "lib/blather/core/stanzas/error.rb", "lib/blather/core/stanzas/iq.rb", "lib/blather/core/stanzas/iqs/queries/roster.rb", "lib/blather/core/stanzas/iqs/query.rb", "lib/blather/core/stanzas/message.rb", "lib/blather/core/stanzas/presence.rb", "lib/blather/core/stanzas/presences/status.rb", "lib/blather/core/stanzas/presences/subscription.rb", "lib/blather/core/stream.rb", "lib/blather/core/streams/parser.rb", "lib/blather/core/streams/resource.rb", "lib/blather/core/streams/sasl.rb", "lib/blather/core/streams/session.rb", "lib/blather/core/streams/tls.rb", "lib/blather/core/sugar.rb", "lib/blather/core/xmpp_node.rb", "lib/blather/extensions/last_activity.rb", "lib/blather/extensions/version.rb", "lib/blather.rb", "LICENSE", "Manifest", "Rakefile", "README", "spec/blather/core/jid_spec.rb", "spec/blather/core/roster_item_spec.rb", "spec/blather/core/roster_spec.rb", "spec/blather/core/stanza_spec.rb", "spec/blather/core/stream_spec.rb", "spec/blather/core/xmpp_node_spec.rb", "spec/spec_helper.rb", "blather.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Blather", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{squishtech}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{An evented XMPP library written on EventMachine and libxml-ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
      s.add_runtime_dependency(%q<libxml>, [">= 0"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<libxml>, [">= 0"])
      s.add_dependency(%q<echoe>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<libxml>, [">= 0"])
    s.add_dependency(%q<echoe>, [">= 0"])
  end
end
