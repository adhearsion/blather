require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe Blather::XMPPNode do
  before { @doc = Nokogiri::XML::Document.new }

  it 'generates a new node automatically setting the document' do
    n = Blather::XMPPNode.new 'foo'
    n.element_name.must_equal 'foo'
    n.document.wont_equal @doc
  end

  it 'sets the new document root to the node' do
    n = Blather::XMPPNode.new 'foo'
    n.document.root.must_equal n
  end

  it 'does not set the document root if the document is provided' do
    n = Blather::XMPPNode.new 'foo', @doc
    n.document.root.wont_equal n
  end

  it 'generates a new node with the given document' do
    n = Blather::XMPPNode.new 'foo', @doc
    n.element_name.must_equal 'foo'
    n.document.must_equal @doc
  end

  it 'generates a node based on the registered_name' do
    foo = Class.new(Blather::XMPPNode)
    foo.registered_name = 'foo'
    foo.new.element_name.must_equal 'foo'
  end

  it 'sets the namespace on creation' do
    foo = Class.new(Blather::XMPPNode)
    foo.registered_ns = 'foo'
    foo.new('foo').namespace.href.must_equal 'foo'
  end

  it 'registers sub classes' do
    class RegistersSubClass < Blather::XMPPNode; register 'foo', 'foo:bar'; end
    RegistersSubClass.registered_name.must_equal 'foo'
    RegistersSubClass.registered_ns.must_equal 'foo:bar'
    Blather::XMPPNode.class_from_registration('foo', 'foo:bar').must_equal RegistersSubClass
  end

  it 'imports another node' do
    class ImportSubClass < Blather::XMPPNode; register 'foo', 'foo:bar'; end
    n = Blather::XMPPNode.new('foo')
    n.namespace = 'foo:bar'
    Blather::XMPPNode.import(n).must_be_kind_of ImportSubClass
  end

  it 'provides an attribute_reader' do
    foo = Class.new(Blather::XMPPNode) { attribute_reader :bar }.new
    foo.must_respond_to :bar
    foo.bar.must_be_nil
    foo[:bar] = 'baz'
    foo.bar.must_equal 'baz'
  end

  it 'provides an attribute_reader with converstion' do
    foo = Class.new(Blather::XMPPNode) { attribute_reader :bar, :call => :to_sym }.new
    foo.must_respond_to :bar
    foo.bar.must_be_nil
    foo[:bar] = 'baz'
    foo.bar.must_equal :baz
  end

  it 'provides an attribute_writer' do
    foo = Class.new(Blather::XMPPNode) { attribute_writer :bar }.new
    foo[:bar].must_be_nil
    foo.bar = 'baz'
    foo[:bar].must_equal 'baz'
  end

  it 'provides an attribute_accessor' do
    foo = Class.new(Blather::XMPPNode) do
      attribute_accessor :bar, :call => :to_sym
      attribute_accessor :baz
    end.new
    foo.must_respond_to :bar
    foo.bar.must_be_nil
    foo.bar = 'fiz'
    foo.bar.must_equal :fiz

    foo.must_respond_to :baz
    foo.baz.must_be_nil
    foo.baz = 'buz'
    foo.baz.must_equal 'buz'
  end

  it 'provides a content reader' do
    foo = Class.new(Blather::XMPPNode) { content_attr_reader :bar }.new('foo')
    foo << (bar = Blather::XMPPNode.new('bar', foo.document))
    bar.content = 'baz'
    foo.must_respond_to :bar
    foo.bar.must_equal 'baz'
  end

  it 'provides a content reader that converts the value' do
    foo = Class.new(Blather::XMPPNode) { content_attr_reader :bar, :to_sym }.new('foo')
    foo << (bar = Blather::XMPPNode.new('bar', foo.document))
    bar.content = 'baz'
    foo.must_respond_to :bar
    foo.bar.must_equal :baz
  end

  it 'provides a content reader with a different node' do
    foo = Class.new(Blather::XMPPNode) { content_attr_reader :bar, nil, :fiz }.new('foo')
    foo << (fiz = Blather::XMPPNode.new('fiz', foo.document))
    fiz.content = 'baz'
    foo.must_respond_to :bar
    foo.bar.must_equal 'baz'
  end

  it 'provides a content writer' do
    foo = Class.new(Blather::XMPPNode) { content_attr_writer :bar }.new('foo')
    foo.must_respond_to :bar=
    foo.bar = 'baz'
    foo.content_from(:bar).must_equal 'baz'
  end

  it 'provides a content writer with a different node' do
    foo = Class.new(Blather::XMPPNode) { content_attr_writer :bar, :fiz }.new('foo')
    foo.must_respond_to :bar=
    foo.bar = 'baz'
    foo.content_from(:fiz).must_equal 'baz'
  end

  it 'provides a content accessor' do
    foo = Class.new(Blather::XMPPNode) { content_attr_accessor :bar }.new('foo')
    foo << (bar = Blather::XMPPNode.new('bar', foo.document))
    foo.must_respond_to :bar=
    foo.must_respond_to :bar
    foo.bar = 'baz'
    foo.bar.must_equal 'baz'
  end

  it 'provides a content accessor with conversion' do
    foo = Class.new(Blather::XMPPNode) { content_attr_accessor :bar, :to_sym }.new('foo')
    foo << (bar = Blather::XMPPNode.new('bar', foo.document))
    foo.must_respond_to :bar=
    foo.must_respond_to :bar
    foo.bar = 'baz'
    foo.bar.must_equal :baz
  end

  it 'provides a content writer that removes a child when set to nil' do
    foo = Class.new(Blather::XMPPNode) { content_attr_writer :bar }.new('foo')
    foo << (bar = Blather::XMPPNode.new('bar', foo.document))
    bar.content = 'baz'
    foo.content_from(:bar).must_equal 'baz'
    foo.xpath('bar').wont_be_empty

    foo.must_respond_to :bar=
    foo.bar = nil
    foo.content_from(:bar).must_be_nil
    foo.xpath('bar').must_be_empty
  end

  it 'can convert itself into a stanza' do
    class StanzaConvert < Blather::XMPPNode; register 'foo'; end
    n = Blather::XMPPNode.new('foo')
    n.to_stanza.must_be_kind_of StanzaConvert
  end

  it 'provides "attr_accessor" for namespace' do
    n = Blather::XMPPNode.new('foo')
    n.namespace.must_be_nil

    n.namespace = 'foo:bar'
    n.namespace_href.must_equal 'foo:bar'
  end

  it 'will remove a child element' do
    n = Blather::XMPPNode.new 'foo'
    n << Blather::XMPPNode.new('bar', n.document)
    n << Blather::XMPPNode.new('bar', n.document)

    n.find(:bar).size.must_equal 2
    n.remove_child 'bar'
    n.find(:bar).size.must_equal 1
  end

  it 'will remove a child with a specific xmlns' do
    n = Blather::XMPPNode.new 'foo'
    n << Blather::XMPPNode.new('bar')
    c = Blather::XMPPNode.new('bar')
    c.namespace = 'foo:bar'
    n << c

    n.find(:bar).size.must_equal 2
    n.remove_child 'bar', 'foo:bar'
    n.find(:bar).size.must_equal 1
    n.find(:bar).first.namespace.must_be_nil
  end

  it 'will remove all child elements' do
    n = Blather::XMPPNode.new 'foo'
    n << Blather::XMPPNode.new('bar')
    n << Blather::XMPPNode.new('bar')

    n.find(:bar).size.must_equal 2
    n.remove_children 'bar'
    n.find(:bar).size.must_equal 0
  end

  it 'provides a copy mechanism' do
    n = Blather::XMPPNode.new 'foo'
    n2 = n.copy
    n2.object_id.wont_equal n.object_id
    n2.element_name.must_equal n.element_name
  end

  it 'provides an inhert mechanism' do
    n = Blather::XMPPNode.new 'foo'
    n2 = Blather::XMPPNode.new 'foo'
    n2.content = 'bar'
    n2['foo'] = 'bar'

    n.inherit(n2)
    n['foo'].must_equal 'bar'
    n.content.must_equal 'bar'
  end

  it 'provides a mechanism to inherit attrs' do
    n = Blather::XMPPNode.new 'foo'
    n2 = Blather::XMPPNode.new 'foo'
    n2['foo'] = 'bar'

    n.inherit_attrs(n2.attributes)
    n['foo'].must_equal 'bar'
  end

  it 'has a content_from helper that pulls the content from a child node' do
    f = Blather::XMPPNode.new('foo')
    f << (b = Blather::XMPPNode.new('bar'))
    b.content = 'content'
    f.content_from(:bar).must_equal 'content'
  end

  it 'returns nil when sent #content_from and a missing node' do
    f = Blather::XMPPNode.new('foo')
    f.content_from(:bar).must_be_nil
  end

  it 'creates a new node and sets content when sent #set_content_for' do
    f = Blather::XMPPNode.new('foo')
    f.must_respond_to :set_content_for
    f.xpath('bar').must_be_empty
    f.set_content_for :bar, :baz
    f.xpath('bar').wont_be_empty
    f.xpath('bar').first.content.must_equal 'baz'
  end

  it 'removes a child node when sent #set_content_for with nil' do
    f = Blather::XMPPNode.new('foo')
    f << (b = Blather::XMPPNode.new('bar'))
    f.must_respond_to :set_content_for
    f.xpath('bar').wont_be_empty
    f.set_content_for :bar, nil
    f.xpath('bar').must_be_empty
  end

  it 'will change the content of an existing node when sent #set_content_for' do
    f = Blather::XMPPNode.new('foo')
    f << (b = Blather::XMPPNode.new('bar'))
    b.content = 'baz'
    f.must_respond_to :set_content_for
    f.xpath('bar').wont_be_empty
    f.xpath('bar').first.content.must_equal 'baz'
    control = f.xpath('bar').first.pointer_id

    f.set_content_for :bar, 'fiz'
    f.xpath('bar').first.content.must_equal 'fiz'
    f.xpath('bar').first.pointer_id.must_equal control
  end
end
