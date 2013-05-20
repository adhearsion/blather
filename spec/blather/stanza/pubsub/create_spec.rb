require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Create do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:create, 'http://jabber.org/protocol/pubsub').should == Blather::Stanza::PubSub::Create
  end

  it 'can be imported' do
    Blather::XMPPNode.parse(<<-NODE).should be_instance_of Blather::Stanza::PubSub::Create
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
    create.xpath('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'ensures a configure node is present on create' do
    create = Blather::Stanza::PubSub::Create.new
    create.xpath('//ns:pubsub/ns:configure', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'ensures a create node exists when calling #create_node' do
    create = Blather::Stanza::PubSub::Create.new
    create.pubsub.remove_children :create
    create.xpath('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns).should be_empty

    create.create_node.should_not be_nil
    create.xpath('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'defaults to a set node' do
    create = Blather::Stanza::PubSub::Create.new
    create.type.should == :set
  end

  it 'sets the host if requested' do
    create = Blather::Stanza::PubSub::Create.new :set, 'pubsub.jabber.local'
    create.to.should == Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    create = Blather::Stanza::PubSub::Create.new :set, 'host', 'node-name'
    create.node.should == 'node-name'
  end
end
