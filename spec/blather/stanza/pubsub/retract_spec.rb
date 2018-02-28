require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Retract do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:retract, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Retract)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(retract_xml)).to be_instance_of Blather::Stanza::PubSub::Retract
  end

  it 'ensures an retract node is present on create' do
    retract = Blather::Stanza::PubSub::Retract.new
    expect(retract.find('//ns:pubsub/ns:retract', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures an retract node exists when calling #retract' do
    retract = Blather::Stanza::PubSub::Retract.new
    retract.pubsub.remove_children :retract
    expect(retract.find('//ns:pubsub/ns:retract', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(retract.retract).not_to be_nil
    expect(retract.find('//ns:pubsub/ns:retract', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    retract = Blather::Stanza::PubSub::Retract.new
    expect(retract.type).to eq(:set)
  end

  it 'sets the host if requested' do
    retract = Blather::Stanza::PubSub::Retract.new 'pubsub.jabber.local'
    expect(retract.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    retract = Blather::Stanza::PubSub::Retract.new 'host', 'node-name'
    expect(retract.node).to eq('node-name')
  end

  it 'can set the retractions as a string' do
    retract = Blather::Stanza::PubSub::Retract.new 'host', 'node'
    retract.retractions = 'id1'
    expect(retract.xpath('//ns:retract[ns:item[@id="id1"]]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'can set the retractions as an array' do
    retract = Blather::Stanza::PubSub::Retract.new 'host', 'node'
    retract.retractions = %w[id1 id2]
    expect(retract.xpath('//ns:retract[ns:item[@id="id1"] and ns:item[@id="id2"]]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'will iterate over each item' do
    retract = Blather::Stanza::PubSub::Retract.new.inherit parse_stanza(retract_xml).root
    expect(retract.retractions.size).to eq(1)
    expect(retract.size).to eq(retract.retractions.size)
    expect(retract.retractions).to eq(%w[ae890ac52d0df67ed7cfdf51b644e901])
  end

  it 'has a node attribute' do
    retract = Blather::Stanza::PubSub::Retract.new
    expect(retract).to respond_to :node
    expect(retract.node).to be_nil
    retract.node = 'node-name'
    expect(retract.node).to eq('node-name')
    expect(retract.xpath('//ns:retract[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'will iterate over each retraction' do
    Blather::XMPPNode.parse(retract_xml).each do |i|
      expect(i).to include "ae890ac52d0df67ed7cfdf51b644e901"
    end
  end
end
