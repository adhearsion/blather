require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSubOwner do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub#owner')).to eq(Blather::Stanza::PubSubOwner)
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Blather::Stanza::PubSubOwner.new
    expect(pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns)).not_to be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Blather::Stanza::PubSubOwner.new
    pubsub.remove_children :pubsub
    expect(pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns)).to be_nil

    expect(pubsub.pubsub).not_to be_nil
    expect(pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSubOwner.registered_ns)).not_to be_nil
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSubOwner.new :get, 'pubsub.jabber.local'
    expect(aff.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end
end
