require File.expand_path "../../../../spec_helper", __FILE__
require File.expand_path "../../../../fixtures/pubsub", __FILE__

describe Blather::Stanza::PubSub::Subscription do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:subscription, 'http://jabber.org/protocol/pubsub').must_equal Blather::Stanza::PubSub::Subscription
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(subscription_xml).root).must_be_instance_of Blather::Stanza::PubSub::Subscription
  end

  it 'ensures an subscription node is present on create' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'ensures an subscription node exists when calling #subscription_node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    subscription.pubsub.remove_children :subscription
    subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns).must_be_empty

    subscription.subscription_node.wont_be_nil
    subscription.find('//ns:pubsub/ns:subscription', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node', 'jid', 'subid', :none
    subscription.type.must_equal :set
  end

  it 'sets the host if requested' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'pubsub.jabber.local', 'node', 'jid', 'subid', :none
    subscription.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.node.must_equal 'node-name'
  end

  it 'has a node attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.node.must_equal 'node-name'

    subscription.node = 'new-node'
    subscription.find('//ns:pubsub/ns:subscription[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.node.must_equal 'new-node'
  end

  it 'has a jid attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.jid.must_equal Blather::JID.new('jid')

    subscription.jid = Blather::JID.new('n@d/r')
    subscription.find('//ns:pubsub/ns:subscription[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.jid.must_equal Blather::JID.new('n@d/r')
  end

  it 'has a subid attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.subid.must_equal 'subid'

    subscription.subid = 'new-subid'
    subscription.find('//ns:pubsub/ns:subscription[@subid="new-subid"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.subid.must_equal 'new-subid'
  end

  it 'has a subscription attribute' do
    subscription = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :none
    subscription.find('//ns:pubsub/ns:subscription[@subscription="none"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.subscription.must_equal :none

    subscription.subscription = :pending
    subscription.find('//ns:pubsub/ns:subscription[@subscription="pending"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
    subscription.subscription.must_equal :pending
  end

  it 'ensures subscription is one of Stanza::PubSub::Subscription::VALID_TYPES' do
    lambda { Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', :invalid_type_name }.must_raise(Blather::ArgumentError)

    Blather::Stanza::PubSub::Subscription::VALID_TYPES.each do |valid_type|
      n = Blather::Stanza::PubSub::Subscription.new :set, 'host', 'node-name', 'jid', 'subid', valid_type
      n.subscription.must_equal valid_type
    end
  end

  Blather::Stanza::PubSub::Subscription::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Blather::Stanza::PubSub::Subscription.new.must_respond_to :"#{valid_type}?"
    end
  end
  
end
