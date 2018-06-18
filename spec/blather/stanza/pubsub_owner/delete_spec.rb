require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSubOwner::Delete do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:delete, 'http://jabber.org/protocol/pubsub#owner')).to eq(Blather::Stanza::PubSubOwner::Delete)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(<<-NODE)).to be_instance_of Blather::Stanza::PubSubOwner::Delete
    <iq type='set'
        from='hamlet@denmark.lit/elsinore'
        to='pubsub.shakespeare.lit'
        id='delete1'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
        <delete node='princely_musings'/>
      </pubsub>
    </iq>
    NODE
  end

  it 'ensures an delete node is present on delete' do
    delete = Blather::Stanza::PubSubOwner::Delete.new
    expect(delete.find('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns)).not_to be_empty
  end

  it 'ensures an delete node exists when calling #delete_node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new
    delete.pubsub.remove_children :delete
    expect(delete.find('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns)).to be_empty

    expect(delete.delete_node).not_to be_nil
    expect(delete.find('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new
    expect(delete.type).to eq(:set)
  end

  it 'sets the host if requested' do
    delete = Blather::Stanza::PubSubOwner::Delete.new :set, 'pubsub.jabber.local'
    expect(delete.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new :set, 'host', 'node-name'
    expect(delete.node).to eq('node-name')
  end
end
