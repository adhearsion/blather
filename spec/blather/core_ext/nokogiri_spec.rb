require 'spec_helper'

describe 'Nokogiri::XML::Node' do
  before { @doc = Nokogiri::XML::Document.new }

  it 'aliases #name to #element_name' do
    node = Nokogiri::XML::Node.new 'foo', @doc
    node.must_respond_to :element_name
    node.element_name.must_equal node.name
  end

  it 'aliases #name= to #element_name=' do
    node = Nokogiri::XML::Node.new 'foo', @doc
    node.must_respond_to :element_name=
    node.element_name.must_equal node.name
    node.element_name = 'bar'
    node.element_name.must_equal 'bar'
  end

  it 'allows symbols as hash keys for attributes' do
    attrs = Nokogiri::XML::Node.new('foo', @doc)
    attrs['foo'] = 'bar'

    attrs['foo'].must_equal 'bar'
    attrs[:foo].must_equal 'bar'
  end

  it 'ensures a string is passed to the attribute setter' do
    attrs = Nokogiri::XML::Node.new('foo', @doc)
    attrs[:foo] = 1
    attrs[:foo].must_equal '1'

    attrs[:jid] = Blather::JID.new('n@d/r')
    attrs[:jid].must_equal 'n@d/r'
  end

  it 'removes an attribute when set to nil' do
    attrs = Nokogiri::XML::Node.new('foo', @doc)
    attrs['foo'] = 'bar'

    attrs['foo'].must_equal 'bar'
    attrs['foo'] = nil
    attrs['foo'].must_be_nil
  end

  it 'allows attribute values to change' do
    attrs = Nokogiri::XML::Node.new('foo', @doc)
    attrs['foo'] = 'bar'

    attrs['foo'].must_equal 'bar'
    attrs['foo'] = 'baz'
    attrs['foo'].must_equal 'baz'
  end

  it 'allows symbols as the path in #xpath' do
    node = Nokogiri::XML::Node.new('foo', @doc)
    node.must_respond_to :find
    @doc.root = node
    @doc.xpath(:foo).first.wont_be_nil
    @doc.xpath(:foo).first.must_equal @doc.xpath('/foo').first
  end

  it 'allows symbols as namespace names in #xpath' do
    node = Nokogiri::XML::Node.new('foo', @doc)
    node.namespace = node.add_namespace('bar', 'baz')
    @doc.root = node
    node.xpath('/bar:foo', :bar => 'baz').first.wont_be_nil
  end

  it 'aliases #xpath to #find' do
    node = Nokogiri::XML::Node.new('foo', @doc)
    node.must_respond_to :find
    @doc.root = node
    node.find('/foo').first.wont_be_nil
  end

  it 'has a helper function #find_first' do
    node = Nokogiri::XML::Node.new('foo', @doc)
    node.must_respond_to :find
    @doc.root = node
    node.find_first('/foo').must_equal node.find('/foo').first
  end
end
