require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSubOwner::Purge do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:purge, 'http://jabber.org/protocol/pubsub#owner').must_equal Blather::Stanza::PubSubOwner::Purge
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(<<-NODE).root).must_be_instance_of Blather::Stanza::PubSubOwner::Purge
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
    purge.find('//ns:pubsub/ns:purge', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
  end

  it 'ensures an purge node exists when calling #purge_node' do
    purge = Blather::Stanza::PubSubOwner::Purge.new
    purge.pubsub.remove_children :purge
    purge.find('//ns:pubsub/ns:purge', :ns => Blather::Stanza::PubSubOwner.registered_ns).must_be_empty

    purge.purge_node.wont_be_nil
    purge.find('//ns:pubsub/ns:purge', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    purge = Blather::Stanza::PubSubOwner::Purge.new
    purge.type.must_equal :set
  end

  it 'sets the host if requested' do
    purge = Blather::Stanza::PubSubOwner::Purge.new :set, 'pubsub.jabber.local'
    purge.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    purge = Blather::Stanza::PubSubOwner::Purge.new :set, 'host', 'node-name'
    purge.node.must_equal 'node-name'
  end
end