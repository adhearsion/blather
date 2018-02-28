require 'spec_helper'
require 'fixtures/pubsub'

describe Blather::Stanza::PubSub::Items do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:items, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Items)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(items_all_nodes_xml)).to be_instance_of Blather::Stanza::PubSub::Items
  end

  it 'ensures an items node is present on create' do
    items = Blather::Stanza::PubSub::Items.new
    expect(items.find('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures an items node exists when calling #items' do
    items = Blather::Stanza::PubSub::Items.new
    items.pubsub.remove_children :items
    expect(items.find('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(items.items).not_to be_nil
    expect(items.find('//ns:pubsub/ns:items', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'defaults to a get node' do
    aff = Blather::Stanza::PubSub::Items.new
    expect(aff.type).to eq(:get)
  end

  it 'ensures newly inherited items are PubSubItem objects' do
    items = Blather::XMPPNode.parse(items_all_nodes_xml)
    expect(items.map { |i| i.class }.uniq).to eq([Blather::Stanza::PubSub::PubSubItem])
  end

  it 'will iterate over each item' do
    n = parse_stanza items_all_nodes_xml
    items = Blather::Stanza::PubSub::Items.new.inherit n.root
    count = 0
    items.each { |i| expect(i).to be_instance_of Blather::Stanza::PubSub::PubSubItem; count += 1 }
    expect(count).to eq(4)
  end

  it 'can create an items request node to request all items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'

    items = Blather::Stanza::PubSub::Items.request host, node
    expect(items.find("//ns:items[@node=\"#{node}\"]", :ns => Blather::Stanza::PubSub.registered_ns).size).to eq(1)
    expect(items.to).to eq(Blather::JID.new(host))
    expect(items.node).to eq(node)
  end

  it 'can create an items request node to request some items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    items = %w[item1 item2]

    items_xpath = items.map { |i| "@id=\"#{i}\"" } * ' or '

    items = Blather::Stanza::PubSub::Items.request host, node, items
    expect(items.find("//ns:items[@node=\"#{node}\"]/ns:item[#{items_xpath}]", :ns => Blather::Stanza::PubSub.registered_ns).size).to eq(2)
    expect(items.to).to eq(Blather::JID.new(host))
    expect(items.node).to eq(node)
  end

  it 'can create an items request node to request "max_number" of items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    max = 3

    items = Blather::Stanza::PubSub::Items.request host, node, nil, max
    expect(items.find("//ns:pubsub/ns:items[@node=\"#{node}\" and @max_items=\"#{max}\"]", :ns => Blather::Stanza::PubSub.registered_ns).size).to eq(1)
    expect(items.to).to eq(Blather::JID.new(host))
    expect(items.node).to eq(node)
    expect(items.max_items).to eq(max)
  end
end
