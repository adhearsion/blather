require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSubOwner::Delete do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:delete, 'http://jabber.org/protocol/pubsub#owner').should == Blather::Stanza::PubSubOwner::Delete
  end

  it 'can be imported' do
    Blather::XMPPNode.parse(<<-NODE).should be_instance_of Blather::Stanza::PubSubOwner::Delete
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
    delete.xpath('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns).should_not be_empty
  end

  it 'ensures an delete node exists when calling #delete_node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new
    delete.pubsub.remove_children :delete
    delete.xpath('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns).should be_empty

    delete.delete_node.should_not be_nil
    delete.xpath('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns).should_not be_empty
  end

  it 'defaults to a set node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new
    delete.type.should == :set
  end

  it 'sets the host if requested' do
    delete = Blather::Stanza::PubSubOwner::Delete.new :set, 'pubsub.jabber.local'
    delete.to.should == Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new :set, 'host', 'node-name'
    delete.node.should == 'node-name'
  end
end
