require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Unsubscribe do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:unsubscribe, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Unsubscribe)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(unsubscribe_xml)).to be_instance_of Blather::Stanza::PubSub::Unsubscribe
  end

  it 'ensures an unsubscribe node is present on create' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures an unsubscribe node exists when calling #unsubscribe' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    unsubscribe.pubsub.remove_children :unsubscribe
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(unsubscribe.unsubscribe).not_to be_nil
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node', 'jid'
    expect(unsubscribe.type).to eq(:set)
  end

  it 'sets the host if requested' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'pubsub.jabber.local', 'node', 'jid'
    expect(unsubscribe.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    expect(unsubscribe.node).to eq('node-name')
  end

  it 'has a node attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(unsubscribe.node).to eq('node-name')

    unsubscribe.node = 'new-node'
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe[@node="new-node"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(unsubscribe.node).to eq('new-node')
  end

  it 'has a jid attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe[@jid="jid"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(unsubscribe.jid).to eq(Blather::JID.new('jid'))

    unsubscribe.jid = Blather::JID.new('n@d/r')
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe[@jid="n@d/r"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(unsubscribe.jid).to eq(Blather::JID.new('n@d/r'))
  end

  it 'has a subid attribute' do
    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid'
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    unsubscribe = Blather::Stanza::PubSub::Unsubscribe.new :set, 'host', 'node-name', 'jid', 'subid'
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe[@subid="subid"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(unsubscribe.subid).to eq('subid')

    unsubscribe.subid = 'newsubid'
    expect(unsubscribe.find('//ns:pubsub/ns:unsubscribe[@subid="newsubid"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
    expect(unsubscribe.subid).to eq('newsubid')
  end
end
