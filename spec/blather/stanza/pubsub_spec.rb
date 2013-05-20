require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub').should == Blather::Stanza::PubSub
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Blather::Stanza::PubSub.new
    pubsub.at_xpath('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Blather::Stanza::PubSub.new
    pubsub.remove_children :pubsub
    pubsub.at_xpath('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns).should be_nil

    pubsub.pubsub.should_not be_nil
    pubsub.at_xpath('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_nil
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSub.new :get, 'pubsub.jabber.local'
    aff.to.should == Blather::JID.new('pubsub.jabber.local')
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    pubsub = Blather::XMPPNode.parse(items_all_nodes_xml)
    pubsub.items.map { |i| i.class }.uniq.should == [Blather::Stanza::PubSub::PubSubItem]
  end
end

describe Blather::Stanza::PubSub::PubSubItem do
  it 'can be initialized with just an ID' do
    id = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new id
    item.id.should == id
  end

  it 'can be initialized with a payload' do
    payload = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    item.payload.should == payload
  end

  it 'allows the payload to be set' do
    item = Blather::Stanza::PubSub::Items::PubSubItem.new
    item.payload.should be_nil
    item.payload = 'testing'
    item.payload.should == 'testing'
    item.content.should == 'testing'
  end

  it 'allows the payload to be unset' do
    payload = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    item.payload.should == payload
    item.payload = nil
    item.payload.should be_nil
  end

  it 'makes payloads readable as string' do
    payload = Blather::XMPPNode.new 'foo'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'bar', payload
    item.payload.should == payload.to_s
  end
end
