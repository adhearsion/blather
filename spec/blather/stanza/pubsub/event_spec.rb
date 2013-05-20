require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Event do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:event, 'http://jabber.org/protocol/pubsub#event').should == Blather::Stanza::PubSub::Event
  end

  it 'is importable' do
    Blather::XMPPNode.parse(event_notification_xml).should be_instance_of Blather::Stanza::PubSub::Event
  end

  it 'ensures a query node is present on create' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.xpath('ns:event', :ns => Blather::Stanza::PubSub::Event.registered_ns).should_not be_empty
  end

  it 'ensures an event node exists when calling #event_node' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.remove_children :event
    evt.xpath('*[local-name()="event"]').should be_empty

    evt.event_node.should_not be_nil
    evt.xpath('ns:event', :ns => Blather::Stanza::PubSub::Event.registered_ns).should_not be_empty
  end

  it 'ensures an items node exists when calling #items_node' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.remove_children :items
    evt.xpath('*[local-name()="items"]').should be_empty

    evt.items_node.should_not be_nil
    evt.xpath('ns:event/ns:items', :ns => Blather::Stanza::PubSub::Event.registered_ns).should_not be_empty
  end

  it 'knows the associated node name' do
    evt = Blather::XMPPNode.parse(event_with_payload_xml)
    evt.node.should == 'princely_musings'
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    evt = Blather::XMPPNode.parse(event_with_payload_xml)
    evt.items?.should == true
    evt.retractions?.should == false
    evt.items.map { |i| i.class }.uniq.should == [Blather::Stanza::PubSub::PubSubItem]
  end

  it 'will iterate over each item' do
    evt = Blather::XMPPNode.parse(event_with_payload_xml)
    evt.items.each { |i| i.class.should == Blather::Stanza::PubSub::PubSubItem }
  end

  it 'handles receiving subscription ids' do
    evt = Blather::XMPPNode.parse(event_subids_xml)
    evt.subscription_ids.should == ['123-abc', '004-yyy']
  end

  it 'can have a list of retractions' do
    evt = Blather::XMPPNode.parse(<<-NODE)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <items node='princely_musings'>
          <retract id='ae890ac52d0df67ed7cfdf51b644e901'/>
        </items>
      </event>
    </message>
    NODE
    evt.retractions?.should == true
    evt.items?.should == false
    evt.retractions.should == %w[ae890ac52d0df67ed7cfdf51b644e901]
  end

  it 'can be a purge' do
    evt = Blather::XMPPNode.parse(<<-NODE)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <purge node='princely_musings'/>
      </event>
    </message>
    NODE
    evt.purge?.should_not be_nil
    evt.node.should == 'princely_musings'
  end

  it 'can be a subscription notification' do
    evt = Blather::XMPPNode.parse(<<-NODE)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <subscription jid='francisco@denmark.lit' subscription='subscribed' node='/example.com/test'/>
      </event>
    </message>
    NODE
    evt.subscription?.should_not be_nil
    evt.subscription[:jid].should == 'francisco@denmark.lit'
    evt.subscription[:subscription].should == 'subscribed'
    evt.subscription[:node].should == '/example.com/test'
  end
end
