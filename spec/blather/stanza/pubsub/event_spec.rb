require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

module Blather
  describe 'Blather::Stanza::PubSub::Event' do
    it 'registers itself' do
      XMPPNode.class_from_registration(:event, 'http://jabber.org/protocol/pubsub#event').must_equal Stanza::PubSub::Event
    end

    it 'is importable' do
      XMPPNode.import(parse_stanza(event_notification_xml).root).must_be_instance_of Stanza::PubSub::Event
    end

    it 'ensures a query node is present on create' do
      evt = Stanza::PubSub::Event.new
      evt.find('ns:event', :ns => Stanza::PubSub::Event.registered_ns).wont_be_empty
    end

    it 'ensures an event node exists when calling #event_node' do
      evt = Stanza::PubSub::Event.new
      evt.remove_children :event
      evt.find('*[local-name()="event"]').must_be_empty

      evt.event_node.wont_be_nil
      evt.find('ns:event', :ns => Stanza::PubSub::Event.registered_ns).wont_be_empty
    end

    it 'ensures an items node exists when calling #items_node' do
      evt = Stanza::PubSub::Event.new
      evt.remove_children :items
      evt.find('*[local-name()="items"]').must_be_empty

      evt.items_node.wont_be_nil
      evt.find('ns:event/ns:items', :ns => Stanza::PubSub::Event.registered_ns).wont_be_empty
    end

    it 'knows the associated node name' do
      evt = XMPPNode.import(parse_stanza(event_with_payload_xml).root)
      evt.node.must_equal 'princely_musings'
    end

    it 'ensures newly inherited items are PubSubItem objects' do
      evt = XMPPNode.import(parse_stanza(event_with_payload_xml).root)
      evt.items.map { |i| i.class }.uniq.must_equal [Stanza::PubSub::PubSubItem]
    end

    it 'will iterate over each item' do
      evt = XMPPNode.import(parse_stanza(event_with_payload_xml).root)
      evt.items.each { |i| i.class.must_equal Stanza::PubSub::PubSubItem }
    end

    it 'handles receiving subscription ids' do
      evt = XMPPNode.import(parse_stanza(event_subids_xml).root)
      evt.subscription_ids.must_equal ['123-abc', '004-yyy']
    end
  end
end
