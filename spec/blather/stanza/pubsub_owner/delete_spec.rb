require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

describe Blather::Stanza::PubSubOwner::Delete do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:delete, 'http://jabber.org/protocol/pubsub#owner').must_equal Blather::Stanza::PubSubOwner::Delete
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(<<-NODE).root).must_be_instance_of Blather::Stanza::PubSubOwner::Delete
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
    delete.find('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
  end

  it 'ensures an delete node exists when calling #delete_node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new
    delete.pubsub.remove_children :delete
    delete.find('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns).must_be_empty

    delete.delete_node.wont_be_nil
    delete.find('//ns:pubsub/ns:delete', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new
    delete.type.must_equal :set
  end

  it 'sets the host if requested' do
    delete = Blather::Stanza::PubSubOwner::Delete.new :set, 'pubsub.jabber.local'
    delete.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    delete = Blather::Stanza::PubSubOwner::Delete.new :set, 'host', 'node-name'
    delete.node.must_equal 'node-name'
  end
end
