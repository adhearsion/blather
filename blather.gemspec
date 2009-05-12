# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{blather}
  s.version = "0.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeff Smick"]
  s.date = %q{2009-05-12}
  s.email = %q{sprsquish@gmail.com}
  s.extensions = ["Rakefile"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "examples/drb_client.rb",
    "examples/echo.rb",
    "examples/print_heirarchy.rb",
    "ext/extconf.rb",
    "ext/push_parser.c",
    "lib/blather.rb",
    "lib/blather/client.rb",
    "lib/blather/client/client.rb",
    "lib/blather/client/dsl.rb",
    "lib/blather/core_ext/active_support.rb",
    "lib/blather/core_ext/libxml.rb",
    "lib/blather/errors.rb",
    "lib/blather/errors/sasl_error.rb",
    "lib/blather/errors/stanza_error.rb",
    "lib/blather/errors/stream_error.rb",
    "lib/blather/jid.rb",
    "lib/blather/roster.rb",
    "lib/blather/roster_item.rb",
    "lib/blather/stanza.rb",
    "lib/blather/stanza/disco.rb",
    "lib/blather/stanza/disco/disco_info.rb",
    "lib/blather/stanza/disco/disco_items.rb",
    "lib/blather/stanza/iq.rb",
    "lib/blather/stanza/iq/query.rb",
    "lib/blather/stanza/iq/roster.rb",
    "lib/blather/stanza/message.rb",
    "lib/blather/stanza/presence.rb",
    "lib/blather/stanza/presence/status.rb",
    "lib/blather/stanza/presence/subscription.rb",
    "lib/blather/stanza/pubsub/subscriber.rb",
    "lib/blather/stream.rb",
    "lib/blather/stream/client.rb",
    "lib/blather/stream/component.rb",
    "lib/blather/stream/parser.rb",
    "lib/blather/stream/resource.rb",
    "lib/blather/stream/sasl.rb",
    "lib/blather/stream/session.rb",
    "lib/blather/stream/stream_handler.rb",
    "lib/blather/stream/tls.rb",
    "lib/blather/xmpp_node.rb"
  ]
  s.homepage = %q{http://github.com/sprsquish/blather}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{squishtech}
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{An evented XMPP library written on EventMachine and libxml-ruby}
  s.test_files = [
    "spec/blather/client/client_spec.rb",
    "spec/blather/client/dsl_spec.rb",
    "spec/blather/client_spec.rb",
    "spec/blather/core_ext/libxml_spec.rb",
    "spec/blather/errors/sasl_error_spec.rb",
    "spec/blather/errors/stanza_error_spec.rb",
    "spec/blather/errors/stream_error_spec.rb",
    "spec/blather/errors_spec.rb",
    "spec/blather/jid_spec.rb",
    "spec/blather/roster_item_spec.rb",
    "spec/blather/roster_spec.rb",
    "spec/blather/stanza/discos/disco_info_spec.rb",
    "spec/blather/stanza/discos/disco_items_spec.rb",
    "spec/blather/stanza/iq/query_spec.rb",
    "spec/blather/stanza/iq/roster_spec.rb",
    "spec/blather/stanza/iq_spec.rb",
    "spec/blather/stanza/message_spec.rb",
    "spec/blather/stanza/presence/status_spec.rb",
    "spec/blather/stanza/presence/subscription_spec.rb",
    "spec/blather/stanza/presence_spec.rb",
    "spec/blather/stanza/pubsub/subscriber_spec.rb",
    "spec/blather/stanza_spec.rb",
    "spec/blather/stream/client_spec.rb",
    "spec/blather/stream/component_spec.rb",
    "spec/blather/xmpp_node_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.6"])
      s.add_runtime_dependency(%q<libxml-ruby>, [">= 1.1.3"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.6"])
      s.add_dependency(%q<libxml-ruby>, [">= 1.1.3"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.6"])
    s.add_dependency(%q<libxml-ruby>, [">= 1.1.3"])
  end
end
