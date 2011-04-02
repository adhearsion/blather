require File.expand_path "../../../../spec_helper", __FILE__
require File.expand_path "../../../../fixtures/pubsub", __FILE__

describe Blather::Stanza::PubSub::Subscribe do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:subscribe, 'http://jabber.org/protocol/pubsub').must_equal Blather::Stanza::PubSub::Subscribe
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(subscribe_xml).root).must_be_instance_of Blather::Stanza::PubSub::Subscribe
  end

  it 'ensures an subscribe node is present on create' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'ensures an subscribe node exists when calling #subscribe' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    subscribe.pubsub.remove_children :subscribe
    subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns).must_be_empty

    subscribe.subscribe.wont_be_nil
    subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    subscribe.type.must_equal :set
  end

  it 'sets the host if requested' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'pubsub.jabber.local', 'node', 'jid'
    subscribe.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    subscribe.node.must_equal 'node-name'
  end

  it 'has a node attribute' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    subscribe.find('//ns:pubsub/ns:subscribe[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscribe.node.must_equal 'node-name'

    subscribe.node = 'new-node'
    subscribe.find('//ns:pubsub/ns:subscribe[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscribe.node.must_equal 'new-node'
  end

  it 'has a jid attribute' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    subscribe.find('//ns:pubsub/ns:subscribe[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscribe.jid.must_equal Blather::JID.new('jid')

    subscribe.jid = Blather::JID.new('n@d/r')
    subscribe.find('//ns:pubsub/ns:subscribe[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscribe.jid.must_equal Blather::JID.new('n@d/r')
  end
end
