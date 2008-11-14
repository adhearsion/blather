require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::XMPPNode' do
  it 'generates a new node' do
    n = XMPPNode.new 'foo'
    n.element_name.must_equal 'foo'
  end

  it 'generates a node based on the current name' do
    class Foo < XMPPNode; end
    Foo.name = 'foo'
    Foo.new.element_name.must_equal 'foo'
  end

  it 'sets the namespace on creation' do
    class Foo < XMPPNode; end
    Foo.xmlns = 'foo'
    Foo.new('foo').xmlns.must_equal 'foo'
  end

  it 'registers sub classes' do
    class Foo < XMPPNode; register 'foo', 'foo:bar'; end
    Foo.name.must_equal 'foo'
    Foo.xmlns.must_equal 'foo:bar'
    XMPPNode.class_from_registration('foo', 'foo:bar').must_equal Foo
  end

  it 'imports another node' do
    class Foo < XMPPNode; register 'foo', 'foo:bar'; end
    n = XMPPNode.new('foo')
    n.xmlns = 'foo:bar'
    XMPPNode.import(n).must_be_kind_of Foo
  end

  it 'can convert itself into a stanza' do
    class Foo < XMPPNode; register 'foo'; end
    n = XMPPNode.new('foo')
    n.to_stanza.must_be_kind_of Foo
  end

  it 'provides "attr_accessor" for xmlns' do
    n = XMPPNode.new('foo')
    n.xmlns.must_be_nil
    n['xmlns'].must_be_nil

    n.xmlns = 'foo:bar'
    n.xmlns.must_equal 'foo:bar'
    n['xmlns'].must_equal 'foo:bar'
  end

  it 'will remove a child element' do
    n = XMPPNode.new 'foo'
    n << XMPPNode.new('bar')
    n << XMPPNode.new('bar')

    n.find('bar').size.must_equal 2
    n.remove_child 'bar'
    n.find('bar').size.must_equal 1
  end

  it 'will remove a child with a specific xmlns' do
    n = XMPPNode.new 'foo'
    n << XMPPNode.new('bar')
    c = XMPPNode.new('bar')
    c.xmlns = 'foo:bar'
    n << c

    n.find('bar').size.must_equal 2
    n.remove_child 'bar', 'foo:bar'
    n.find('bar').size.must_equal 1
    n.find('bar').first.xmlns.must_be_nil
  end

  it 'will remove all child elements' do
    n = XMPPNode.new 'foo'
    n << XMPPNode.new('bar')
    n << XMPPNode.new('bar')

    n.find('bar').size.must_equal 2
    n.remove_children 'bar'
    n.find('bar').size.must_equal 0
  end

  it 'provides a helper to grab content from a child' do
    n = XMPPNode.new 'foo'
    n << XMPPNode.new('bar', 'baz')
    n.content_from(:bar).must_equal 'baz'
  end

  it 'provides a copy mechanism' do
    n = XMPPNode.new 'foo'
    n2 = n.copy
    n2.object_id.wont_equal n.object_id
    n2.element_name.must_equal n.element_name
  end

  it 'provides an inhert mechanism' do
    n = XMPPNode.new 'foo'
    n2 = XMPPNode.new 'foo', 'bar'
    n2['foo'] = 'bar'

    n.inherit(n2)
    n['foo'].must_equal 'bar'
    n.content.must_equal 'bar'
  end

  it 'provides a mechanism to inherit attrs' do
    n = XMPPNode.new 'foo'
    n2 = XMPPNode.new 'foo'
    n2['foo'] = 'bar'

    n.inherit_attrs(n2.attributes)
    n['foo'].must_equal 'bar'
  end

  it 'cuts line breaks out of #to_s' do
    n = XMPPNode.new 'foo'
    n << XMPPNode.new('bar', 'baz')
    n.to_s.scan(">\n<").size.must_equal 0
  end

  it 'overrides #find to find without xpath' do
    n = XMPPNode.new 'foo'
    n << XMPPNode.new('bar', 'baz')
    n.find('bar').must_be_kind_of Array

    XML::Document.new.root = n
    n.find('bar').must_be_kind_of XML::XPath::Object
  end
end
