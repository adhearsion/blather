require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Unsubscribe do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:unsubscribe, 'http://jabber.org/protocol/pubsub').should == Blather::Stanza::PubSub::Unsubscribe
  end

  it 'can be imported' do
    Blather::XMPPNode.parse(unsubscribe_xml).should be_instance_of Blather::Stanza::PubSub::Unsubscribe
  end

  it 'ensures an unsubscribe node is present on create' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'ensures an unsubscribe node exists when calling #unsubscribe' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    unsubscribe.pubsub.remove_children :unsubscribe
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns).should be_empty

    unsubscribe.unsubscribe.should_not be_nil
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'defaults to a set node' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    unsubscribe.type.should == :set
  end

  it 'sets the host if requested' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'pubsub.jabber.local', 'node', 'jid'
    unsubscribe.to.should == Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.node.should == 'node-name'
  end

  it 'has a node attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    unsubscribe.node.should == 'node-name'

    unsubscribe.node = 'new-node'
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    unsubscribe.node.should == 'new-node'
  end

  it 'has a jid attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    unsubscribe.jid.should == Blather::JID.new('jid')

    unsubscribe.jid = Blather::JID.new('n@d/r')
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    unsubscribe.jid.should == Blather::JID.new('n@d/r')
  end

  it 'has a subid attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns).should be_empty

    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid', 'subid'
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    unsubscribe.subid.should == 'subid'

    unsubscribe.subid = 'newsubid'
    unsubscribe.xpath('//ns:pubsub/ns:unsubscribe[@subid="newsubid"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    unsubscribe.subid.should == 'newsubid'
  end
end
