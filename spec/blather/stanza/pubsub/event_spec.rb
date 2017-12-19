require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Event do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:event, 'http://jabber.org/protocol/pubsub#event')).to eq(Blather::Stanza::PubSub::Event)
  end

  it 'is importable' do
    expect(Blather::XMPPNode.parse(event_notification_xml)).to be_instance_of Blather::Stanza::PubSub::Event
  end

  it 'ensures a query node is present on create' do
    evt = Blather::Stanza::PubSub::Event.new
    expect(evt.find('ns:event', :ns => Blather::Stanza::PubSub::Event.registered_ns)).not_to be_empty
  end

  it 'ensures an event node exists when calling #event_node' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.remove_children :event
    expect(evt.find('*[local-name()="event"]')).to be_empty

    expect(evt.event_node).not_to be_nil
    expect(evt.find('ns:event', :ns => Blather::Stanza::PubSub::Event.registered_ns)).not_to be_empty
  end

  it 'ensures an items node exists when calling #items_node' do
    evt = Blather::Stanza::PubSub::Event.new
    evt.remove_children :items
    expect(evt.find('*[local-name()="items"]')).to be_empty

    expect(evt.items_node).not_to be_nil
    expect(evt.find('ns:event/ns:items', :ns => Blather::Stanza::PubSub::Event.registered_ns)).not_to be_empty
  end

  it 'knows the associated node name' do
    evt = Blather::XMPPNode.parse(event_with_payload_xml)
    expect(evt.node).to eq('princely_musings')
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    evt = Blather::XMPPNode.parse(event_with_payload_xml)
    expect(evt.items?).to eq(true)
    expect(evt.retractions?).to eq(false)
    expect(evt.items.map { |i| i.class }.uniq).to eq([Blather::Stanza::PubSub::PubSubItem])
  end

  it 'will iterate over each item' do
    evt = Blather::XMPPNode.parse(event_with_payload_xml)
    evt.items.each { |i| expect(i.class).to eq(Blather::Stanza::PubSub::PubSubItem) }
  end

  it 'handles receiving subscription ids' do
    evt = Blather::XMPPNode.parse(event_subids_xml)
    expect(evt.subscription_ids).to eq(['123-abc', '004-yyy'])
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
    expect(evt.retractions?).to eq(true)
    expect(evt.items?).to eq(false)
    expect(evt.retractions).to eq(%w[ae890ac52d0df67ed7cfdf51b644e901])
  end

  it 'can be a purge' do
    evt = Blather::XMPPNode.parse(<<-NODE)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <purge node='princely_musings'/>
      </event>
    </message>
    NODE
    expect(evt.purge?).not_to be_nil
    expect(evt.node).to eq('princely_musings')
  end

  it 'can be a subscription notification' do
    evt = Blather::XMPPNode.parse(<<-NODE)
    <message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
      <event xmlns='http://jabber.org/protocol/pubsub#event'>
        <subscription jid='francisco@denmark.lit' subscription='subscribed' node='/example.com/test'/>
      </event>
    </message>
    NODE
    expect(evt.subscription?).not_to be_nil
    expect(evt.subscription[:jid]).to eq('francisco@denmark.lit')
    expect(evt.subscription[:subscription]).to eq('subscribed')
    expect(evt.subscription[:node]).to eq('/example.com/test')
  end
end
