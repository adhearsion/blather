require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::PubSub' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Stanza::PubSub.new
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.wont_be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Stanza::PubSub.new
    pubsub.remove_child :pubsub
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.must_be_nil

    pubsub.pubsub.wont_be_nil
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.wont_be_nil
  end

  it 'sets the host if requested' do
    aff = Stanza::PubSub.new :get, 'pubsub.jabber.local'
    aff.to.must_equal JID.new('pubsub.jabber.local')
  end
end
