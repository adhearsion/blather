require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

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
    Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/disco#items').must_equal Blather::Stanza::Iq::DiscoItems
  end

  it 'must be importable' do
    Blather::XMPPNode.import(parse_stanza(disco_items_xml).root).must_be_instance_of Blather::Stanza::Iq::DiscoItems
  end

  it 'is constructed properly' do
    n = Blather::Stanza::Iq::DiscoItems.new :get, '/path/to/node'
    n.to = 'to@jid.com'
    n.find("/iq[@to='to@jid.com' and @type='get' and @id='#{n.id}']/ns:query[@node='/path/to/node']", :ns => Blather::Stanza::Iq::DiscoItems.registered_ns).wont_be_empty
  end

  it 'has a node attribute' do
    n = Blather::Stanza::Iq::DiscoItems.new nil, 'music', []
    n.node.must_equal 'music'
    n.node = :foo
    n.node.must_equal 'foo'
  end

  it 'inherits a list of identities' do
    n = parse_stanza disco_items_xml
    r = Blather::Stanza::Iq::DiscoItems.new.inherit n.root
    r.items.size.must_equal 3
    r.items.map { |i| i.class }.uniq.must_equal [Blather::Stanza::Iq::DiscoItems::Item]
  end

  it 'takes a list of hashes for items' do
    items = [
      {:jid => 'foo@bar/baz', :node => 'node', :name => 'name'},
      {:jid => 'baz@foo/bar', :node => 'node1', :name => 'name1'},
    ]

    control = [ Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name]),
                Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, items
    di.items.size.must_equal 2
    di.items.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a list of Item objects as items' do
    control = [ Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name]),
                Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, control
    di.items.size.must_equal 2
    di.items.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a single hash as identity' do
    control = [Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, {:jid => 'foo@bar/baz', :node => 'node', :name => 'name'}
    di.items.size.must_equal 1
    di.items.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a single identity object as identity' do
    control = [Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, control.first
    di.items.size.must_equal 1
    di.items.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a mix of hashes and identity objects as items' do
    items = [
      {:jid => 'foo@bar/baz', :node => 'node', :name => 'name'},
      Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1]),
    ]

    control = [ Blather::Stanza::Iq::DiscoItems::Item.new(*%w[foo@bar/baz node name]),
                Blather::Stanza::Iq::DiscoItems::Item.new(*%w[baz@foo/bar node1 name1])]

    di = Blather::Stanza::Iq::DiscoItems.new nil, nil, items
    di.items.size.must_equal 2
    di.items.each { |i| control.include?(i).must_equal true }
  end
end

describe Blather::Stanza::Iq::DiscoItems::Item do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<item jid='foo@bar/baz' node='music' name='Music from the time of Shakespeare' />"
    i = Blather::Stanza::Iq::DiscoItems::Item.new n.root
    i.jid.must_equal Blather::JID.new('foo@bar/baz')
    i.node.must_equal 'music'
    i.name.must_equal 'Music from the time of Shakespeare'
  end

  it 'has a jid attribute' do
    n = Blather::Stanza::Iq::DiscoItems::Item.new 'foo@bar/baz'
    n.jid.must_be_kind_of Blather::JID
    n.jid.must_equal Blather::JID.new('foo@bar/baz')
    n.jid = 'baz@foo/bar'
    n.jid.must_equal Blather::JID.new('baz@foo/bar')
  end

  it 'has a node attribute' do
    n = Blather::Stanza::Iq::DiscoItems::Item.new 'foo@bar/baz', 'music'
    n.node.must_equal 'music'
    n.node = 'book'
    n.node.must_equal 'book'
  end

  it 'has a name attribute' do
    n = Blather::Stanza::Iq::DiscoItems::Item.new 'foo@bar/baz', nil, 'Music from the time of Shakespeare'
    n.name.must_equal 'Music from the time of Shakespeare'
    n.name = 'Books by and about Shakespeare'
    n.name.must_equal 'Books by and about Shakespeare'
  end

  it 'raises an error when compared against a non DiscoItems::Item' do
    a = Blather::Stanza::Iq::DiscoItems::Item.new('foo@bar/baz')
    lambda { a == 'test' }.must_raise RuntimeError
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoItems::Item.new('foo@bar/baz')
    a.must_equal Blather::Stanza::Iq::DiscoItems::Item.new('foo@bar/baz')
    a.wont_equal Blather::Stanza::Iq::DiscoItems::Item.new('not-foo@bar/baz')
  end
end
