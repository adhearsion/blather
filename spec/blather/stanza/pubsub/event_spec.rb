require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

describe 'Blather::Stanza::PubSub::Event' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:event, 'http://jabber.org/protocol/pubsub#event').must_equal Stanza::PubSub::Event
  end

  it 'knows the associated node name' do
    n = XML::Document.string event_with_payload_xml
    event = Stanza::PubSub::Event.new.inherit n.root
    event.node.must_equal 'princely_musings'
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    n = XML::Document.string event_with_payload_xml
    event = Stanza::PubSub::Event.new.inherit n.root
    event.items.map { |i| i.class }.uniq.must_equal [Stanza::PubSub::PubSubItem]
  end

  it 'will iterate over each item' do
    n = XML::Document.string event_with_payload_xml
    event = Stanza::PubSub::Event.new.inherit n.root
    event.items.each { |i| i.class.must_equal Stanza::PubSub::PubSubItem }
  end

  it 'can be imported' do
    n = XML::Document.string event_with_payload_xml
    event = XMPPNode.import n.root
    event.class.must_equal Stanza::PubSub::Event
  end
end
