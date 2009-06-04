require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

describe Blather::Stanza::PubSubOwner::Create do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:create, 'http://jabber.org/protocol/pubsub#owner').must_equal Blather::Stanza::PubSubOwner::Create
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(<<-NODE).root).must_be_instance_of Blather::Stanza::PubSubOwner::Create
    <iq type='set'
        from='hamlet@denmark.lit/elsinore'
        to='pubsub.shakespeare.lit'
        id='create1'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
        <create node='princely_musings'/>
      </pubsub>
    </iq>
    NODE
  end

  it 'ensures an create node is present on create' do
    create = Blather::Stanza::PubSubOwner::Create.new
    create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
  end

  it 'ensures an create node exists when calling #create_node' do
    create = Blather::Stanza::PubSubOwner::Create.new
    create.pubsub.remove_children :create
    create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSubOwner.registered_ns).must_be_empty

    create.create_node.wont_be_nil
    create.find('//ns:pubsub/ns:create', :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    create = Blather::Stanza::PubSubOwner::Create.new
    create.type.must_equal :set
  end

  it 'sets the host if requested' do
    create = Blather::Stanza::PubSubOwner::Create.new :set, 'pubsub.jabber.local'
    create.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    create = Blather::Stanza::PubSubOwner::Create.new :set, 'host', 'node-name'
    create.node.must_equal 'node-name'
  end
end