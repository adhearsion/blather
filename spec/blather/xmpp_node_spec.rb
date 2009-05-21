require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

module Blather
  describe 'Blather::XMPPNode' do
    before { @doc = Nokogiri::XML::Document.new }

    it 'generates a new node automatically setting the document' do
      n = XMPPNode.new 'foo'
      n.element_name.must_equal 'foo'
      n.document.wont_equal @doc
    end

    it 'generates a new node with the given document' do
      n = XMPPNode.new 'foo', @doc
      n.element_name.must_equal 'foo'
      n.document.must_equal @doc
    end

    it 'generates a node based on the registered_name' do
      foo = Class.new(XMPPNode)
      foo.registered_name = 'foo'
      foo.new.element_name.must_equal 'foo'
    end

    it 'sets the namespace on creation' do
      foo = Class.new(XMPPNode)
      foo.registered_ns = 'foo'
      foo.new('foo').namespace.href.must_equal 'foo'
    end

    it 'registers sub classes' do
      class RegistersSubClass < XMPPNode; register 'foo', 'foo:bar'; end
      RegistersSubClass.registered_name.must_equal 'foo'
      RegistersSubClass.registered_ns.must_equal 'foo:bar'
      XMPPNode.class_from_registration('foo', 'foo:bar').must_equal RegistersSubClass
    end

    it 'imports another node' do
      class ImportSubClass < XMPPNode; register 'foo', 'foo:bar'; end
      n = XMPPNode.new('foo')
      n.namespace = 'foo:bar'
      XMPPNode.import(n).must_be_kind_of ImportSubClass
    end

    it 'provides an attribute_reader' do
      foo = Class.new(XMPPNode) { attribute_reader :bar }.new
      foo.must_respond_to :bar
      foo.bar.must_be_nil
      foo[:bar] = 'baz'
      foo.bar.must_equal :baz
    end

    it 'provides an attribute_reader and not convert to syms' do
      foo = Class.new(XMPPNode) { attribute_reader :bar, :to_sym => false }.new
      foo.must_respond_to :bar
      foo.bar.must_be_nil
      foo[:bar] = 'baz'
      foo.bar.must_equal 'baz'
    end

    it 'provides an attribute_writer' do
      foo = Class.new(XMPPNode) { attribute_writer :bar }.new
      foo[:bar].must_be_nil
      foo.bar = 'baz'
      foo[:bar].must_equal 'baz'
    end

    it 'provides an attribute_accessor' do
      foo = Class.new(XMPPNode) do
        attribute_accessor :bar
        attribute_accessor :baz, :to_sym => false
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

    it 'can convert itself into a stanza' do
      class StanzaConvert < XMPPNode; register 'foo'; end
      n = XMPPNode.new('foo')
      n.to_stanza.must_be_kind_of StanzaConvert
    end

    it 'provides "attr_accessor" for namespace' do
      n = XMPPNode.new('foo')
      n.namespace.must_be_nil

      n.namespace = 'foo:bar'
      n.namespace_href.must_equal 'foo:bar'
    end

    it 'will remove a child element' do
      n = XMPPNode.new 'foo'
      n << XMPPNode.new('bar', n.document)
      n << XMPPNode.new('bar', n.document)

      n.find(:bar).size.must_equal 2
      n.remove_child 'bar'
      n.find(:bar).size.must_equal 1
    end

    it 'will remove a child with a specific xmlns' do
      n = XMPPNode.new 'foo'
      n << XMPPNode.new('bar')
      c = XMPPNode.new('bar')
      c.namespace = 'foo:bar'
      n << c

      n.find(:bar).size.must_equal 2
      n.remove_child 'bar', 'foo:bar'
      n.find(:bar).size.must_equal 1
      n.find(:bar).first.namespace.must_be_nil
    end

    it 'will remove all child elements' do
      n = XMPPNode.new 'foo'
      n << XMPPNode.new('bar')
      n << XMPPNode.new('bar')

      n.find(:bar).size.must_equal 2
      n.remove_children 'bar'
      n.find(:bar).size.must_equal 0
    end

    it 'provides a copy mechanism' do
      n = XMPPNode.new 'foo'
      n2 = n.copy
      n2.object_id.wont_equal n.object_id
      n2.element_name.must_equal n.element_name
    end

    it 'provides an inhert mechanism' do
      n = XMPPNode.new 'foo'
      n2 = XMPPNode.new 'foo'
      n2.content = 'bar'
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
  end
end
