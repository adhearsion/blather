require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSubOwner::Purge do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:purge, 'http://jabber.org/protocol/pubsub#owner')).to eq(Blather::Stanza::PubSubOwner::Purge)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(<<-NODE)).to be_instance_of Blather::Stanza::PubSubOwner::Purge
    <iq type='set'
        from='hamlet@denmark.lit/elsinore'
        to='pubsub.shakespeare.lit'
        id='purge1'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
        <purge node='princely_musings'/>
      </pubsub>
    </iq>
    NODE
  end

  it 'ensures an purge node is present on create' do
    purge = Blather::Stanza::PubSubOwner::Purge.new
    expect(purge.find('//ns:pubsub/ns:purge', :ns => Blather::Stanza::PubSubOwner.registered_ns)).not_to be_empty
  end

  it 'ensures an purge node exists when calling #purge_node' do
    purge = Blather::Stanza::PubSubOwner::Purge.new
    purge.pubsub.remove_children :purge
    expect(purge.find('//ns:pubsub/ns:purge', :ns => Blather::Stanza::PubSubOwner.registered_ns)).to be_empty

    expect(purge.purge_node).not_to be_nil
    expect(purge.find('//ns:pubsub/ns:purge', :ns => Blather::Stanza::PubSubOwner.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    purge = Blather::Stanza::PubSubOwner::Purge.new
    expect(purge.type).to eq(:set)
  end

  it 'sets the host if requested' do
    purge = Blather::Stanza::PubSubOwner::Purge.new :set, 'pubsub.jabber.local'
    expect(purge.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    purge = Blather::Stanza::PubSubOwner::Purge.new :set, 'host', 'node-name'
    expect(purge.node).to eq('node-name')
  end
end
