require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

describe Blather::Stanza::PubSub::Event do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:event, 'http://jabber.org/protocol/pubsub#event').must_equal Blather::Stanza::PubSub::Event
  end

  it 'is importable' do
    Blather::XMPPNode.import(parse_stanza(event_notification_xml).root).must_be_instance_of Blather::Stanza::PubSub::Event
  end

  it 'ensures a query node is present on create' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.find('ns:event', :ns => Blather::Stanza::PubSub::Event.registered_ns).wont_be_empty
  end

  it 'ensures an event node exists when calling #event_node' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.remove_children :event
    evt.find('*[local-name()="event"]').must_be_empty

    evt.event_node.wont_be_nil
    evt.find('ns:event', :ns => Blather::Stanza::PubSub::Event.registered_ns).wont_be_empty
  end

  it 'ensures an items node exists when calling #items_node' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.remove_children :items
    evt.find('*[local-name()="items"]').must_be_empty

    evt.items_node.wont_be_nil
    evt.find('ns:event/ns:items', :ns => Blather::Stanza::PubSub::Event.registered_ns).wont_be_empty
  end

  it 'knows the associated node name' do
    evt = Blather::XMPPNode.import(parse_stanza(event_with_payload_xml).root)
    evt.node.must_equal 'princely_musings'
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    evt = Blather::XMPPNode.import(parse_stanza(event_with_payload_xml).root)
    evt.items?.must_equal true
    evt.retractions?.must_equal false
    evt.items.map { |i| i.class }.uniq.must_equal [Blather::Stanza::PubSub::PubSubItem]
  end

  it 'will iterate over each item' do
    evt = Blather::XMPPNode.import(parse_stanza(event_with_payload_xml).root)
    evt.items.each { |i| i.class.must_equal Blather::Stanza::PubSub::PubSubItem }
  end

  it 'handles receiving subscription ids' do
    evt = Blather::XMPPNode.import(parse_stanza(event_subids_xml).root)
    evt.subscription_ids.must_equal ['123-abc', '004-yyy']
  end

  it 'can have a list of retractions' do
    evt = Blather::XMPPNode.import(parse_stanza(<<-NODE).root)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <items node='princely_musings'>
          <retract id='ae890ac52d0df67ed7cfdf51b644e901'/>
        </items>
      </event>
    </message>
    NODE
    evt.retractions?.must_equal true
    evt.items?.must_equal false
    evt.retractions.must_equal %w[ae890ac52d0df67ed7cfdf51b644e901]
  end

  it 'can be a purge' do
    evt = Blather::XMPPNode.import(parse_stanza(<<-NODE).root)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <purge node='princely_musings'/>
      </event>
    </message>
    NODE
    evt.purge?.wont_be_nil
    evt.node.must_equal 'princely_musings'
  end

  it 'can be a subscription notification' do
    evt = Blather::XMPPNode.import(parse_stanza(<<-NODE).root)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <subscription jid='francisco@denmark.lit' subscription='subscribed' node='/example.com/test'/>
      </event>
    </message>
    NODE
    evt.subscription?.wont_be_nil
    evt.subscription[:jid].must_equal 'francisco@denmark.lit'
    evt.subscription[:subscription].must_equal 'subscribed'
    evt.subscription[:node].must_equal '/example.com/test'
  end
end
