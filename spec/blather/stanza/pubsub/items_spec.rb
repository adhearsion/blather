require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

module Blather
  describe 'Blather::Stanza::PubSub::Items' do
    it 'registers itself' do
      XMPPNode.class_from_registration(:items, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub::Items
    end

    it 'can be imported' do
      XMPPNode.import(parse_stanza(items_all_nodes_xml).root).must_be_instance_of Stanza::PubSub::Items
    end

    it 'ensures an items node is present on create' do
      items = Stanza::PubSub::Items.new
      items.find('//ns:pubsub/ns:items', :ns => Stanza::PubSub.registered_ns).wont_be_empty
    end

    it 'ensures an items node exists when calling #items' do
      items = Stanza::PubSub::Items.new
      items.pubsub.remove_children :items
      items.find('//ns:pubsub/ns:items', :ns => Stanza::PubSub.registered_ns).must_be_empty

      items.items.wont_be_nil
      items.find('//ns:pubsub/ns:items', :ns => Stanza::PubSub.registered_ns).wont_be_empty
    end

    it 'defaults to a get node' do
      aff = Stanza::PubSub::Items.new
      aff.type.must_equal :get
    end

    it 'ensures newly inherited items are PubSubItem objects' do
      items = XMPPNode.import(parse_stanza(items_all_nodes_xml).root)
      items.map { |i| i.class }.uniq.must_equal [Stanza::PubSub::PubSubItem]
    end

    it 'will iterate over each item' do
      n = parse_stanza items_all_nodes_xml
      items = Stanza::PubSub::Items.new.inherit n.root
      count = 0
      items.each { |i| i.class.must_equal Stanza::PubSub::PubSubItem; count += 1 }
      count.must_equal 4
    end

    it 'can create an items request node to request all items' do
      host = 'pubsub.jabber.local'
      node = 'princely_musings'

      items = Stanza::PubSub::Items.request host, node
      items.find("//ns:items[@node=\"#{node}\"]", :ns => Stanza::PubSub.registered_ns).size.must_equal 1
      items.to.must_equal JID.new(host)
      items.node.must_equal node
    end

    it 'can create an items request node to request some items' do
      host = 'pubsub.jabber.local'
      node = 'princely_musings'
      items = %w[item1 item2]

      items_xpath = items.map { |i| "@id=\"#{i}\"" } * ' or '

      items = Stanza::PubSub::Items.request host, node, items
      items.find("//ns:items[@node=\"#{node}\"]/ns:item[#{items_xpath}]", :ns => Stanza::PubSub.registered_ns).size.must_equal 2
      items.to.must_equal JID.new(host)
      items.node.must_equal node
    end

    it 'can create an items request node to request "max_number" of items' do
      host = 'pubsub.jabber.local'
      node = 'princely_musings'
      max = 3

      items = Stanza::PubSub::Items.request host, node, nil, max
      items.find("//ns:pubsub/ns:items[@node=\"#{node}\" and @max_items=\"#{max}\"]", :ns => Stanza::PubSub.registered_ns).size.must_equal 1
      items.to.must_equal JID.new(host)
      items.node.must_equal node
      items.max_items.must_equal max
    end
  end
end
