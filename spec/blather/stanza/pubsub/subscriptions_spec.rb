require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

def control_subscriptions
  { :subscribed => ['node1', 'node2'],
    :unconfigured => ['node3'],
    :pending => ['node4'],
    :none => ['node5'] }
end

describe 'Blather::Stanza::PubSub::Subscriptions' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:pubsub_subscriptions, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub::Subscriptions
  end

  it 'ensures an subscriptions node is present on create' do
    subscriptions = Stanza::PubSub::Subscriptions.new
    subscriptions.pubsub.children.detect { |n| n.element_name == 'subscriptions' }.wont_be_nil
  end

  it 'ensures an subscriptions node exists when calling #subscriptions' do
    subscriptions = Stanza::PubSub::Subscriptions.new
    subscriptions.pubsub.remove_child :subscriptions
    subscriptions.pubsub.children.detect { |n| n.element_name == 'subscriptions' }.must_be_nil

    subscriptions.list.wont_be_nil
    subscriptions.pubsub.children.detect { |n| n.element_name == 'subscriptions' }.wont_be_nil    
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
    node = XML::Document.string(subscriptions_xml).root

    subscriptions = Stanza::PubSub::Subscriptions.new.inherit node
    subscriptions.size.must_equal 4
    subscriptions.list.must_equal control_subscriptions
  end

  it 'will iterate over each subscription' do
    node = XML::Document.string(subscriptions_xml).root
    subscriptions = Stanza::PubSub::Subscriptions.new.inherit node
    subscriptions.each do |type, nodes|
      nodes.must_equal control_subscriptions[type]
    end
  end

  it 'can be accessed via "[]"' do
    node = XML::Document.string(subscriptions_xml).root
    subscriptions = Stanza::PubSub::Subscriptions.new.inherit node
    [:subscribed, :unconfigured, :pending, :none].each do |type|
      subscriptions[type].must_equal control_subscriptions[type]
    end
  end
end
