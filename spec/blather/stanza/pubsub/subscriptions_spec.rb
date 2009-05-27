require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

def control_subscriptions
  { :subscribed => ['node1', 'node2'],
    :unconfigured => ['node3'],
    :pending => ['node4'],
    :none => ['node5'] }
end

module Blather
  describe 'Blather::Stanza::PubSub::Subscriptions' do
    it 'registers itself' do
      XMPPNode.class_from_registration(:subscriptions, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub::Subscriptions
    end

    it 'can be imported' do
      XMPPNode.import(parse_stanza(subscriptions_xml).root).must_be_instance_of Stanza::PubSub::Subscriptions
    end

    it 'ensures an subscriptions node is present on create' do
      subscriptions = Stanza::PubSub::Subscriptions.new
      subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Stanza::PubSub.registered_ns).wont_be_empty
    end

    it 'ensures an subscriptions node exists when calling #subscriptions' do
      subscriptions = Stanza::PubSub::Subscriptions.new
      subscriptions.pubsub.remove_children :subscriptions
      subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Stanza::PubSub.registered_ns).must_be_empty

      subscriptions.list.wont_be_nil
      subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Stanza::PubSub.registered_ns).wont_be_empty
    end

    it 'defaults to a get node' do
      aff = Stanza::PubSub::Subscriptions.new
      aff.type.must_equal :get
    end

    it 'sets the host if requested' do
      aff = Stanza::PubSub::Subscriptions.new :get, 'pubsub.jabber.local'
      aff.to.must_equal JID.new('pubsub.jabber.local')
    end

    it 'can import a subscriptions result node' do
      node = parse_stanza(subscriptions_xml).root

      subscriptions = Stanza::PubSub::Subscriptions.new.inherit node
      subscriptions.size.must_equal 4
      subscriptions.list.must_equal control_subscriptions
    end

    it 'will iterate over each subscription' do
      node = parse_stanza(subscriptions_xml).root
      subscriptions = Stanza::PubSub::Subscriptions.new.inherit node
      subscriptions.each do |type, nodes|
        nodes.must_equal control_subscriptions[type]
      end
    end
  end
end
