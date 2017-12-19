require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Create do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:create, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Create)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(<<-NODE)).to be_instance_of Blather::Stanza::PubSub::Create
    <iq type='set'
        from='hamlet@denmark.lit/elsinore'
        to='pubsub.shakespeare.lit'
        id='create1'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <create node='princely_musings'/>
        <configure/>
      </pubsub>
    </iq>
    NODE
  end

  it 'ensures a create node is present on create' do
    create = Blather::Stanza::PubSub::Create.new
    expect(create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures a configure node is present on create' do
    create = Blather::Stanza::PubSub::Create.new
    expect(create.find('//ns:pubsub/ns:configure', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures a create node exists when calling #create_node' do
    create = Blather::Stanza::PubSub::Create.new
    create.pubsub.remove_children :create
    expect(create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(create.create_node).not_to be_nil
    expect(create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'defaults to a set node' do
    create = Blather::Stanza::PubSub::Create.new
    expect(create.type).to eq(:set)
  end

  it 'sets the host if requested' do
    create = Blather::Stanza::PubSub::Create.new :set, 'pubsub.jabber.local'
    expect(create.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'sets the node' do
    create = Blather::Stanza::PubSub::Create.new :set, 'host', 'node-name'
    expect(create.node).to eq('node-name')
  end
end
