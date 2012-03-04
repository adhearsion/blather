require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Subscription do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:subscription, 'http://jabber.org/protocol/pubsub').should == Blather::Stanza::PubSub::Subscription
  end

  it 'can be imported' do
    Blather::XMPPNode.parse(subscription_xml).should be_instance_of Blather::Stanza::PubSub::Subscription
  end

  it 'ensures an subscription node is present on create' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'ensures an subscription node exists when calling #subscription_node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    subscription.pubsub.remove_children :subscription
    subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns).should be_empty

    subscription.subscription_node.should_not be_nil
    subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'defaults to a set node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    subscription.type.should == :set
  end

  it 'sets the host if requested' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'pubsub.jabber.local', 'node', 'jid', 'subid', :none
    subscription.to.should == Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.node.should == 'node-name'
  end

  it 'has a node attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.node.should == 'node-name'

    subscription.node = 'new-node'
    subscription.find('//ns:pubsub/ns:subscription[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.node.should == 'new-node'
  end

  it 'has a jid attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.jid.should == Blather::JID.new('jid')

    subscription.jid = Blather::JID.new('n@d/r')
    subscription.find('//ns:pubsub/ns:subscription[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.jid.should == Blather::JID.new('n@d/r')
  end

  it 'has a subid attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.subid.should == 'subid'

    subscription.subid = 'new-subid'
    subscription.find('//ns:pubsub/ns:subscription[@subid="new-subid"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.subid.should == 'new-subid'
  end

  it 'has a subscription attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@subscription="none"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.subscription.should == :none

    subscription.subscription = :pending
    subscription.find('//ns:pubsub/ns:subscription[@subscription="pending"]', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
    subscription.subscription.should == :pending
  end

  it 'ensures subscription is one of Stanza::PubSub::Subscription::VALID_TYPES' do
    lambda { Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :invalid_type_name }.should raise_error(Blather::ArgumentError)

    Blather::Stanza::PubSub::Subscription::VALID_TYPES.each do |valid_type|
      n = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', valid_type
      n.subscription.should == valid_type
    end
  end

  Blather::Stanza::PubSub::Subscription::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Blather::Stanza::PubSub::Subscription.new.should respond_to :"#{valid_type}?"
    end
  end

end
