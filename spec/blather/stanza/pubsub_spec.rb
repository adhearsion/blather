require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub)
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Blather::Stanza::PubSub.new
    expect(pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Blather::Stanza::PubSub.new
    pubsub.remove_children :pubsub
    expect(pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns)).to be_nil

    expect(pubsub.pubsub).not_to be_nil
    expect(pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_nil
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSub.new :get, 'pubsub.jabber.local'
    expect(aff.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    pubsub = Blather::XMPPNode.parse(items_all_nodes_xml)
    expect(pubsub.items.map { |i| i.class }.uniq).to eq([Blather::Stanza::PubSub::PubSubItem])
  end
end

describe Blather::Stanza::PubSub::PubSubItem do
  it 'can be initialized with just an ID' do
    id = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new id
    expect(item.id).to eq(id)
  end

  it 'can be initialized with a payload' do
    payload = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    expect(item.payload).to eq(payload)
  end

  it 'allows the payload to be set' do
    item = Blather::Stanza::PubSub::Items::PubSubItem.new
    expect(item.payload).to be_nil
    item.payload = 'testing'
    expect(item.payload).to eq('testing')
    expect(item.content).to eq('testing')
  end

  it 'allows the payload to be unset' do
    payload = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    expect(item.payload).to eq(payload)
    item.payload = nil
    expect(item.payload).to be_nil
  end

  it 'makes payloads readable as string' do
    payload = Blather::XMPPNode.new 'foo'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'bar', payload
    expect(item.payload).to eq(payload.to_s)
  end
end
