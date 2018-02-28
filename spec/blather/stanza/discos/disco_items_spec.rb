require 'spec_helper'

def disco_items_xml
  <<-XML
  <iq type='result'
      from='catalog.shakespeare.lit'
      to='romeo@montague.net/orchard'
      id='items2'>
    <query xmlns='http://jabber.org/protocol/disco#items'>
      <item jid='catalog.shakespeare.lit'
            node='books'
            name='Books by and about Shakespeare'/>
      <item jid='catalog.shakespeare.lit'
            node='clothing'
            name='Wear your literary taste with pride'/>
      <item jid='catalog.shakespeare.lit'
            node='music'
            name='Music from the time of Shakespeare'/>
    </query>
  </iq>
  XML
end

describe Blather::Stanza::Iq::DiscoItems do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/disco#items')).to eq(Blather::Stanza::Iq::DiscoItems)
  end

  it 'must be importable' do
    expect(Blather::XMPPNode.parse(disco_items_xml)).to be_instance_of Blather::Stanza::Iq::DiscoItems
  end

  it 'is constructed properly' do
    n = Blather::Stanza::Iq::DiscoItems.new :get, '/path/to/node'
    n.to = 'to@jid.com'
    expect(n.find("/iq[@to='to@jid.com' and @type='get' and @id='#{n.id}']/ns:query[@node='/path/to/node']", :ns => Blather::Stanza::Iq::DiscoItems.registered_ns)).not_to be_empty
  end

  it 'has a node attribute' do
    n = Blather::Stanza::Iq::DiscoItems.new nil, 'music', []
    expect(n.node).to eq('music')
    n.node = :foo
    expect(n.node).to eq('foo')
  end

  it 'inherits a list of identities' do
    n = parse_stanza disco_items_xml
    r = Blather::Stanza::Iq::DiscoItems.new.inherit n.root
    expect(r.items.size).to eq(3)
    expect(r.items.map { |i| i.class }.uniq).to eq([Blather::Stanza::Iq::DiscoItems::Item])
  end

  it 'takes a list of hashes for items' do
    items = [
      {:jid => 'foo@bar/baz', :node => 'node', :name => 'name'},
      {:jid => 'baz@foo/bar', :node => 'node1', :name => 'name1'},
    ]

    control = [ Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name]),
                Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, items
    expect(di.items.size).to eq(2)
    di.items.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a list of Item objects as items' do
    control = [ Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name]),
                Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, control
    expect(di.items.size).to eq(2)
    di.items.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a single hash as identity' do
    control = [Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, {:jid => 'foo@bar/baz', :node => 'node', :name => 'name'}
    expect(di.items.size).to eq(1)
    di.items.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a single identity object as identity' do
    control = [Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, control.first
    expect(di.items.size).to eq(1)
    di.items.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a mix of hashes and identity objects as items' do
    items = [
      {:jid => 'foo@bar/baz', :node => 'node', :name => 'name'},
      Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1]),
    ]

    control = [ Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name]),
                Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, items
    expect(di.items.size).to eq(2)
    di.items.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'allows adding of items' do
    di = Blather::Stanza::Iq::DiscoItems.new
    expect(di.items.size).to eq(0)
    di.items = [{:jid => 'foo@bar/baz', :node => 'node', :name => 'name'}]
    expect(di.items.size).to eq(1)
    di.items += [Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name])]
    expect(di.items.size).to eq(2)
    di.items = nil
    expect(di.items.size).to eq(0)
  end
end

describe Blather::Stanza::Iq::DiscoItems::Item do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<item jid='foo@bar/baz' node='music' name='Music from the time of Shakespeare' />"
    i = Blather::Stanza::Iq::DiscoItems::Item.new n.root
    expect(i.jid).to eq(Blather::JID.new('foo@bar/baz'))
    expect(i.node).to eq('music')
    expect(i.name).to eq('Music from the time of Shakespeare')
  end

  it 'has a jid attribute' do
    n = Blather::Stanza::Iq::DiscoItems::Item.new 'foo@bar/baz'
    expect(n.jid).to be_kind_of Blather::JID
    expect(n.jid).to eq(Blather::JID.new('foo@bar/baz'))
    n.jid = 'baz@foo/bar'
    expect(n.jid).to eq(Blather::JID.new('baz@foo/bar'))
  end

  it 'has a node attribute' do
    n = Blather::Stanza::Iq::DiscoItems::Item.new 'foo@bar/baz', 'music'
    expect(n.node).to eq('music')
    n.node = 'book'
    expect(n.node).to eq('book')
  end

  it 'has a name attribute' do
    n = Blather::Stanza::Iq::DiscoItems::Item.new 'foo@bar/baz', nil, 'Music from the time of Shakespeare'
    expect(n.name).to eq('Music from the time of Shakespeare')
    n.name = 'Books by and about Shakespeare'
    expect(n.name).to eq('Books by and about Shakespeare')
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoItems::Item.new('foo@bar/baz')
    expect(a).to eq(Blather::Stanza::Iq::DiscoItems::Item.new('foo@bar/baz'))
    expect(a).not_to equal Blather::Stanza::Iq::DiscoItems::Item.new('not-foo@bar/baz')
  end
end
