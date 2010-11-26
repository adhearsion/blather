require File.expand_path "../../../spec_helper", __FILE__
require File.expand_path "../../../fixtures/pubsub", __FILE__

describe Blather::Stanza::PubSubOwner do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub#owner').must_equal Blather::Stanza::PubSubOwner
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Blather::Stanza::PubSubOwner.new
    pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Blather::Stanza::PubSubOwner.new
    pubsub.remove_children :pubsub
    pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns).must_be_nil

    pubsub.pubsub.wont_be_nil
    pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_nil
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSubOwner.new :get, 'pubsub.jabber.local'
    aff.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end
end
