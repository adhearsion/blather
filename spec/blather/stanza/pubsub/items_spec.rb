require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Items do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:items, 'http://jabber.org/protocol/pubsub').should == Blather::Stanza::PubSub::Items
  end

  it 'can be imported' do
    Blather::XMPPNode.parse(items_all_nodes_xml).should be_instance_of Blather::Stanza::PubSub::Items
  end

  it 'ensures an items node is present on create' do
    items = Blather::Stanza::PubSub::Items.new
    items.xpath('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'ensures an items node exists when calling #items' do
    items = Blather::Stanza::PubSub::Items.new
    items.pubsub.remove_children :items
    items.xpath('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns).should be_empty

    items.items.should_not be_nil
    items.xpath('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'defaults to a get node' do
    aff = Blather::Stanza::PubSub::Items.new
    aff.type.should == :get
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    items = Blather::XMPPNode.parse(items_all_nodes_xml)
    items.map { |i| i.class }.uniq.should == [Blather::Stanza::PubSub::PubSubItem]
  end

  it 'will iterate over each item' do
    n = parse_stanza items_all_nodes_xml
    items = Blather::Stanza::PubSub::Items.new.inherit n.root
    count = 0
    items.each { |i| i.should be_instance_of Blather::Stanza::PubSub::PubSubItem; count += 1 }
    count.should == 4
  end

  it 'can create an items request node to request all items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'

    items = Blather::Stanza::PubSub::Items.request host, node
    items.xpath("//ns:items[@node=\"#{node}\"]", :ns => Blather::Stanza::PubSub.registered_ns).size.should == 1
    items.to.should == Blather::JID.new(host)
    items.node.should == node
  end

  it 'can create an items request node to request some items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    items = %w[item1 item2]

    items_xpath = items.map { |i| "@id=\"#{i}\"" } * ' or '

    items = Blather::Stanza::PubSub::Items.request host, node, items
    items.xpath("//ns:items[@node=\"#{node}\"]/ns:item[#{items_xpath}]", :ns => Blather::Stanza::PubSub.registered_ns).size.should == 2
    items.to.should == Blather::JID.new(host)
    items.node.should == node
  end

  it 'can create an items request node to request "max_number" of items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    max = 3

    items = Blather::Stanza::PubSub::Items.request host, node, nil, max
    items.xpath("//ns:pubsub/ns:items[@node=\"#{node}\" and @max_items=\"#{max}\"]", :ns => Blather::Stanza::PubSub.registered_ns).size.should == 1
    items.to.should == Blather::JID.new(host)
    items.node.should == node
    items.max_items.should == max
  end
end
