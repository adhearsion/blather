require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Unsubscribe do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:unsubscribe, 'http://jabber.org/protocol/pubsub').must_equal Blather::Stanza::PubSub::Unsubscribe
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(unsubscribe_xml).root).must_be_instance_of Blather::Stanza::PubSub::Unsubscribe
  end

  it 'ensures an unsubscribe node is present on create' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    unsubscribe.find('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'ensures an unsubscribe node exists when calling #unsubscribe' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    unsubscribe.pubsub.remove_children :unsubscribe
    unsubscribe.find('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns).must_be_empty

    unsubscribe.unsubscribe.wont_be_nil
    unsubscribe.find('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    unsubscribe.type.must_equal :set
  end

  it 'sets the host if requested' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'pubsub.jabber.local', 'node', 'jid'
    unsubscribe.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.node.must_equal 'node-name'
  end

  it 'has a node attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.find('//ns:pubsub/ns:unsubscribe[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    unsubscribe.node.must_equal 'node-name'

    unsubscribe.node = 'new-node'
    unsubscribe.find('//ns:pubsub/ns:unsubscribe[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    unsubscribe.node.must_equal 'new-node'
  end

  it 'has a jid attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.find('//ns:pubsub/ns:unsubscribe[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    unsubscribe.jid.must_equal Blather::JID.new('jid')

    unsubscribe.jid = Blather::JID.new('n@d/r')
    unsubscribe.find('//ns:pubsub/ns:unsubscribe[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    unsubscribe.jid.must_equal Blather::JID.new('n@d/r')
  end

  it 'has a subid attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.find('//ns:pubsub/ns:unsubscribe[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns).must_be_empty

    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid', 'subid'
    unsubscribe.find('//ns:pubsub/ns:unsubscribe[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    unsubscribe.subid.must_equal 'subid'

    unsubscribe.subid = 'newsubid'
    unsubscribe.find('//ns:pubsub/ns:unsubscribe[@subid="newsubid"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    unsubscribe.subid.must_equal 'newsubid'
  end
end
