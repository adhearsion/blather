require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Publish do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:publish, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Publish)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(publish_xml)).to be_instance_of Blather::Stanza::PubSub::Publish
  end

  it 'ensures an publish node is present on create' do
    publish = Blather::Stanza::PubSub::Publish.new
    expect(publish.find('//ns:pubsub/ns:publish', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures an publish node exists when calling #publish' do
    publish = Blather::Stanza::PubSub::Publish.new
    publish.pubsub.remove_children :publish
    expect(publish.find('//ns:pubsub/ns:publish', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(publish.publish).not_to be_nil
    expect(publish.find('//ns:pubsub/ns:publish', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    publish = Blather::Stanza::PubSub::Publish.new
    expect(publish.type).to eq(:set)
  end

  it 'sets the host if requested' do
    publish = Blather::Stanza::PubSub::Publish.new 'pubsub.jabber.local'
    expect(publish.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    publish = Blather::Stanza::PubSub::Publish.new 'host', 'node-name'
    expect(publish.node).to eq('node-name')
  end

  it 'will iterate over each item' do
    publish = Blather::Stanza::PubSub::Publish.new.inherit parse_stanza(publish_xml).root
    count = 0
    publish.each do |i|
      expect(i).to be_instance_of Blather::Stanza::PubSub::PubSubItem
      count += 1
    end
    expect(count).to eq(1)
  end

  it 'has a node attribute' do
    publish = Blather::Stanza::PubSub::Publish.new
    expect(publish).to respond_to :node
    expect(publish.node).to be_nil
    publish.node = 'node-name'
    expect(publish.node).to eq('node-name')
    expect(publish.xpath('//ns:publish[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'can set the payload with a hash' do
    payload = {'id1' => 'payload1', 'id2' => 'payload2'}
    publish = Blather::Stanza::PubSub::Publish.new
    publish.payload = payload
    expect(publish.size).to eq(2)
    expect(publish.xpath('/iq/ns:pubsub/ns:publish[ns:item[@id="id1" and .="payload1"] and ns:item[@id="id2" and .="payload2"]]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'can set the payload with an array' do
    payload = %w[payload1 payload2]
    publish = Blather::Stanza::PubSub::Publish.new
    publish.payload = payload
    expect(publish.size).to eq(2)
    expect(publish.xpath('/iq/ns:pubsub/ns:publish[ns:item[.="payload1"] and ns:item[.="payload2"]]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'can set the payload with a string' do
    publish = Blather::Stanza::PubSub::Publish.new
    publish.payload = 'payload'
    expect(publish.size).to eq(1)
    expect(publish.xpath('/iq/ns:pubsub/ns:publish[ns:item[.="payload"]]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end
end
