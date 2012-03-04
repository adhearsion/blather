require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Subscribe do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:subscribe, 'http://jabber.org/protocol/pubsub').should == Blather::Stanza::PubSub::Subscribe
  end

  it 'can be imported' do
    Blather::XMPPNode.parse(subscribe_xml).should be_instance_of Blather::Stanza::PubSub::Subscribe
  end

  it 'ensures an subscribe node is present on create' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'ensures an subscribe node exists when calling #subscribe' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    subscribe.pubsub.remove_children :subscribe
    subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns).should be_empty

    subscribe.subscribe.should_not be_nil
    subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'defaults to a set node' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    subscribe.type.should == :set
  end

  it 'sets the host if requested' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'pubsub.jabber.local', 'node', 'jid'
    subscribe.to.should == Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    subscribe.node.should == 'node-name'
  end

  it 'has a node attribute' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    subscribe.find('//ns:pubsub/ns:subscribe[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscribe.node.should == 'node-name'

    subscribe.node = 'new-node'
    subscribe.find('//ns:pubsub/ns:subscribe[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscribe.node.should == 'new-node'
  end

  it 'has a jid attribute' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    subscribe.find('//ns:pubsub/ns:subscribe[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscribe.jid.should == Blather::JID.new('jid')

    subscribe.jid = Blather::JID.new('n@d/r')
    subscribe.find('//ns:pubsub/ns:subscribe[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscribe.jid.should == Blather::JID.new('n@d/r')
  end
end
