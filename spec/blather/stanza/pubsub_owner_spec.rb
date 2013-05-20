require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSubOwner do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub#owner').should == Blather::Stanza::PubSubOwner
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Blather::Stanza::PubSubOwner.new
    pubsub.at_xpath('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns).should_not be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Blather::Stanza::PubSubOwner.new
    pubsub.remove_children :pubsub
    pubsub.at_xpath('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns).should be_nil

    pubsub.pubsub.should_not be_nil
    pubsub.at_xpath('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns).should_not be_nil
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSubOwner.new :get, 'pubsub.jabber.local'
    aff.to.should == Blather::JID.new('pubsub.jabber.local')
  end
end
