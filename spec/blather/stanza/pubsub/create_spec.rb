require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Create do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:create, 'http://jabber.org/protocol/pubsub').must_equal Blather::Stanza::PubSub::Create
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(<<-NODE).root).must_be_instance_of Blather::Stanza::PubSub::Create
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
    create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'ensures a configure node is present on create' do
    create = Blather::Stanza::PubSub::Create.new
    create.find('//ns:pubsub/ns:configure', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'ensures a create node exists when calling #create_node' do
    create = Blather::Stanza::PubSub::Create.new
    create.pubsub.remove_children :create
    create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns).must_be_empty

    create.create_node.wont_be_nil
    create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    create = Blather::Stanza::PubSub::Create.new
    create.type.must_equal :set
  end

  it 'sets the host if requested' do
    create = Blather::Stanza::PubSub::Create.new :set, 'pubsub.jabber.local'
    create.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    create = Blather::Stanza::PubSub::Create.new :set, 'host', 'node-name'
    create.node.must_equal 'node-name'
  end
end