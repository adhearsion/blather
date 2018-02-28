require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Subscription do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:subscription, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Subscription)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(subscription_xml)).to be_instance_of Blather::Stanza::PubSub::Subscription
  end

  it 'ensures an subscription node is present on create' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    expect(subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures an subscription node exists when calling #subscription_node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    subscription.pubsub.remove_children :subscription
    expect(subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(subscription.subscription_node).not_to be_nil
    expect(subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    expect(subscription.type).to eq(:set)
  end

  it 'sets the host if requested' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'pubsub.jabber.local', 'node', 'jid', 'subid', :none
    expect(subscription.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    expect(subscription.node).to eq('node-name')
  end

  it 'has a node attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    expect(subscription.find('//ns:pubsub/ns:subscription[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.node).to eq('node-name')

    subscription.node = 'new-node'
    expect(subscription.find('//ns:pubsub/ns:subscription[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.node).to eq('new-node')
  end

  it 'has a jid attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    expect(subscription.find('//ns:pubsub/ns:subscription[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.jid).to eq(Blather::JID.new('jid'))

    subscription.jid = Blather::JID.new('n@d/r')
    expect(subscription.find('//ns:pubsub/ns:subscription[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.jid).to eq(Blather::JID.new('n@d/r'))
  end

  it 'has a subid attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    expect(subscription.find('//ns:pubsub/ns:subscription[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.subid).to eq('subid')

    subscription.subid = 'new-subid'
    expect(subscription.find('//ns:pubsub/ns:subscription[@subid="new-subid"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.subid).to eq('new-subid')
  end

  it 'has a subscription attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    expect(subscription.find('//ns:pubsub/ns:subscription[@subscription="none"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.subscription).to eq(:none)

    subscription.subscription = :pending
    expect(subscription.find('//ns:pubsub/ns:subscription[@subscription="pending"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscription.subscription).to eq(:pending)
  end

  it 'ensures subscription is one of Stanza::PubSub::Subscription::VALID_TYPES' do
    expect { Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :invalid_type_name }.to raise_error(Blather::ArgumentError)

    Blather::Stanza::PubSub::Subscription::VALID_TYPES.each do |valid_type|
      n = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', valid_type
      expect(n.subscription).to eq(valid_type)
    end
  end

  Blather::Stanza::PubSub::Subscription::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      expect(Blather::Stanza::PubSub::Subscription.new).to respond_to :"#{valid_type}?"
    end
  end

end
