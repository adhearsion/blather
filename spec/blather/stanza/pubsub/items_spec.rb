require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

describe 'Blather::Stanza::PubSub::Items' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:pubsub_items, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub::Items
  end

  it 'ensures an items node is present on create' do
    items = Stanza::PubSub::Items.new
    items.pubsub.children.detect { |n| n.element_name == 'items' }.wont_be_nil
  end

  it 'ensures an items node exists when calling #items' do
    items = Stanza::PubSub::Items.new
    items.pubsub.remove_child :items
    items.pubsub.children.detect { |n| n.element_name == 'items' }.must_be_nil

    items.items.wont_be_nil
    items.pubsub.children.detect { |n| n.element_name == 'items' }.wont_be_nil    
  end

  it 'defaults to a get node' do
    aff = Stanza::PubSub::Items.new
    aff.type.must_equal :get
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    n = XML::Document.string items_all_nodes_xml
    items = Stanza::PubSub::Items.new.inherit n.root
    items.map { |i| i.class }.uniq.must_equal [Stanza::PubSub::Items::PubSubItem]
  end

  it 'will iterate over each item' do
    n = XML::Document.string items_all_nodes_xml
    items = Stanza::PubSub::Items.new.inherit n.root
    items.each { |i| i.class.must_equal Stanza::PubSub::Items::PubSubItem }
  end

  it 'can create an items request node to request all items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'

    items = Stanza::PubSub::Items.request host, node
    items.find("//pubsub/items[@node=\"#{node}\"]").size.must_equal 1
    items.to.must_equal JID.new(host)
    items.node.must_equal node
  end

  it 'can create an items request node to request some items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    items = %w[item1 item2]

    items_xpath = items.map { |i| "@id=\"#{i}\"" } * ' or '

    items = Stanza::PubSub::Items.request host, node, items
    items.find("//pubsub/items[@node=\"#{node}\"]/item[#{items_xpath}]").size.must_equal 2
    items.to.must_equal JID.new(host)
    items.node.must_equal node
  end

  it 'can create an items request node to request "max_number" of items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    max = 3

    items = Stanza::PubSub::Items.request host, node, nil, max
    items.find("//pubsub/items[@node=\"#{node}\" and @max_items=\"#{max}\"]").size.must_equal 1
    items.to.must_equal JID.new(host)
    items.node.must_equal node
    items.max_items.must_equal max
  end
end

describe 'Blather::Stanza::PubSub::Items::PubSubItem' do
  it 'can be initialized with just an ID' do
    id = 'foobarbaz'
    item = Stanza::PubSub::Items::PubSubItem.new id
    item.id.must_equal id
  end

  it 'can be initialized with a payload' do
    payload = 'foobarbaz'
    item = Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    item.payload.must_equal payload
  end

  it 'allows the payload to be set' do
    item = Stanza::PubSub::Items::PubSubItem.new
    item.payload.must_be_nil
    item.payload = 'testing'
    item.payload.must_equal 'testing'
  end

  it 'allows the payload to be unset' do
    payload = 'foobarbaz'
    item = Stanza::PubSub::Items::PubSubItem.new 'foo', payload
    item.payload.must_equal payload
    item.payload = nil
    item.payload.must_be_nil
  end
end
