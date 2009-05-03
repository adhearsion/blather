require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::PubSub' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Stanza::PubSub.new
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.wont_be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Stanza::PubSub.new
    pubsub.remove_child :pubsub
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.must_be_nil

    pubsub.pubsub.wont_be_nil
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.wont_be_nil
  end

  it 'can create an items request node to request all items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'

    items = Stanza::PubSub.items host, node
    items.find("//pubsub/items[@node=\"#{node}\"]").size.must_equal 1
    items.to.must_equal JID.new(host)
  end

  it 'can create an items request node to request some items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    items = %w[item1 item2]

    items_xpath = items.map { |i| "@id=\"#{i}\"" } * ' or '

    items = Stanza::PubSub.items host, node, items
    items.find("//pubsub/items[@node=\"#{node}\"]/item[#{items_xpath}]").size.must_equal 2
    items.to.must_equal JID.new(host)
  end

  it 'can create an items request node to request "max_number" of items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    max = 3

    items = Stanza::PubSub.items host, node, nil, max
    items.find("//pubsub/items[@node=\"#{node}\" and @max_items=\"#{max}\"]").size.must_equal 1
    items.to.must_equal JID.new(host)
  end
end
