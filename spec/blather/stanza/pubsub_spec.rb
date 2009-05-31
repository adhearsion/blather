require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe Blather::Stanza::PubSub do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub').must_equal Blather::Stanza::PubSub
  end

  it 'is importable as a subscription' do
    Blather::XMPPNode.import(parse_stanza(<<-XML).root).must_be_instance_of Blather::Stanza::PubSub
      <iq type='result'
          from='pubsub.shakespeare.lit'
          to='francisco@denmark.lit/barracks'
          id='sub1'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
          <subscription
              node='princely_musings'
              jid='francisco@denmark.lit'
              subid='ba49252aaa4f5d320c24d3766f0bdcade78c78d3'
              subscription='subscribed'/>
        </pubsub>
      </iq>
    XML
  end

  it 'is importable as a subscribe' do
    Blather::XMPPNode.import(parse_stanza(<<-XML).root).must_be_instance_of Blather::Stanza::PubSub
      <iq type='set'
          from='francisco@denmark.lit/barracks'
          to='pubsub.shakespeare.lit'
          id='sub1'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
          <subscribe
              node='princely_musings'
              jid='francisco@denmark.lit'/>
        </pubsub>
      </iq>
    XML
  end

  it 'is importable as an unsubscribe' do
    Blather::XMPPNode.import(parse_stanza(<<-XML).root).must_be_instance_of Blather::Stanza::PubSub
      <iq type='set'
          from='francisco@denmark.lit/barracks'
          to='pubsub.shakespeare.lit'
          id='unsub1'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
           <unsubscribe
               node='princely_musings'
               jid='francisco@denmark.lit'/>
        </pubsub>
      </iq>
    XML
    
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Blather::Stanza::PubSub.new
    pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Blather::Stanza::PubSub.new
    pubsub.remove_children :pubsub
    pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns).must_be_nil

    pubsub.pubsub.wont_be_nil
    pubsub.find_first('/iq/ns:pubsub', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_nil
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSub.new :get, 'pubsub.jabber.local'
    aff.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end
end

describe Blather::Stanza::PubSub::Items::PubSubItem do
  it 'can be initialized with just an ID' do
    id = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new id
    item.id.must_equal id
  end

  it 'can be initialized with a payload' do
    payload = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    item.payload.must_equal payload
  end

  it 'allows the payload to be set' do
    item = Blather::Stanza::PubSub::Items::PubSubItem.new
    item.payload.must_be_nil
    item.payload = 'testing'
    item.payload.must_equal 'testing'
    item.content.must_equal 'testing'
  end

  it 'allows the payload to be unset' do
    payload = 'foobarbaz'
    item = Blather::Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    item.payload.must_equal payload
    item.payload = nil
    item.payload.must_be_nil
  end
end
