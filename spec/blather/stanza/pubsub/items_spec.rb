require File.expand_path "../../../../spec_helper", __FILE__
require File.expand_path "../../../../fixtures/pubsub", __FILE__

describe Blather::Stanza::PubSub::Items do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:items, 'http://jabber.org/protocol/pubsub').must_equal Blather::Stanza::PubSub::Items
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(items_all_nodes_xml).root).must_be_instance_of Blather::Stanza::PubSub::Items
  end

  it 'ensures an items node is present on create' do
    items = Blather::Stanza::PubSub::Items.new
    items.find('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'ensures an items node exists when calling #items' do
    items = Blather::Stanza::PubSub::Items.new
    items.pubsub.remove_children :items
    items.find('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns).must_be_empty

    items.items.wont_be_nil
    items.find('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'defaults to a get node' do
    aff = Blather::Stanza::PubSub::Items.new
    aff.type.must_equal :get
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    items = Blather::XMPPNode.import(parse_stanza(items_all_nodes_xml).root)
    items.map { |i| i.class }.uniq.must_equal [Blather::Stanza::PubSub::PubSubItem]
  end

  it 'will iterate over each item' do
    n = parse_stanza items_all_nodes_xml
    items = Blather::Stanza::PubSub::Items.new.inherit n.root
    count = 0
    items.each { |i| i.must_be_instance_of Blather::Stanza::PubSub::PubSubItem; count += 1 }
    count.must_equal 4
  end

  it 'can create an items request node to request all items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'

    items = Blather::Stanza::PubSub::Items.request host, node
    items.find("//ns:items[@node=\"#{node}\"]", :ns => Blather::Stanza::PubSub.registered_ns).size.must_equal 1
    items.to.must_equal Blather::JID.new(host)
    items.node.must_equal node
  end

  it 'can create an items request node to request some items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    items = %w[item1 item2]

    items_xpath = items.map { |i| "@id=\"#{i}\"" } * ' or '

    items = Blather::Stanza::PubSub::Items.request host, node, items
    items.find("//ns:items[@node=\"#{node}\"]/ns:item[#{items_xpath}]", :ns => Blather::Stanza::PubSub.registered_ns).size.must_equal 2
    items.to.must_equal Blather::JID.new(host)
    items.node.must_equal node
  end

  it 'can create an items request node to request "max_number" of items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    max = 3

    items = Blather::Stanza::PubSub::Items.request host, node, nil, max
    items.find("//ns:pubsub/ns:items[@node=\"#{node}\" and @max_items=\"#{max}\"]", :ns => Blather::Stanza::PubSub.registered_ns).size.must_equal 1
    items.to.must_equal Blather::JID.new(host)
    items.node.must_equal node
    items.max_items.must_equal max
  end
end
