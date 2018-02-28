require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Subscribe do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:subscribe, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Subscribe)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(subscribe_xml)).to be_instance_of Blather::Stanza::PubSub::Subscribe
  end

  it 'ensures an subscribe node is present on create' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    expect(subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures an subscribe node exists when calling #subscribe' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    subscribe.pubsub.remove_children :subscribe
    expect(subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(subscribe.subscribe).not_to be_nil
    expect(subscribe.find('//ns:pubsub/ns:subscribe', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node', 'jid'
    expect(subscribe.type).to eq(:set)
  end

  it 'sets the host if requested' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'pubsub.jabber.local', 'node', 'jid'
    expect(subscribe.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    expect(subscribe.node).to eq('node-name')
  end

  it 'has a node attribute' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    expect(subscribe.find('//ns:pubsub/ns:subscribe[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscribe.node).to eq('node-name')

    subscribe.node = 'new-node'
    expect(subscribe.find('//ns:pubsub/ns:subscribe[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscribe.node).to eq('new-node')
  end

  it 'has a jid attribute' do
    subscribe = Blather::Stanza::PubSub::Subscribe.new :set, 'host', 'node-name', 'jid'
    expect(subscribe.find('//ns:pubsub/ns:subscribe[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscribe.jid).to eq(Blather::JID.new('jid'))

    subscribe.jid = Blather::JID.new('n@d/r')
    expect(subscribe.find('//ns:pubsub/ns:subscribe[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(subscribe.jid).to eq(Blather::JID.new('n@d/r'))
  end
end
