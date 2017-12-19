require 'spec_helper'

describe Blather::XMPPNode do
  before { @doc = Nokogiri::XML::Document.new }

  it 'generates a node based on the registered_name' do
    foo = Class.new(Blather::XMPPNode)
    foo.registered_name = 'foo'
    expect(foo.new.element_name).to eq('foo')
  end

  it 'sets the namespace on creation' do
    foo = Class.new(Blather::XMPPNode)
    foo.registered_ns = 'foo'
    expect(foo.new('foo').namespace.href).to eq('foo')
  end

  it 'registers sub classes' do
    class RegistersSubClass < Blather::XMPPNode; register 'foo', 'foo:bar'; end
    expect(RegistersSubClass.registered_name).to eq('foo')
    expect(RegistersSubClass.registered_ns).to eq('foo:bar')
    expect(Blather::XMPPNode.class_from_registration('foo', 'foo:bar')).to eq(RegistersSubClass)
  end

  it 'imports another node' do
    class ImportSubClass < Blather::XMPPNode; register 'foo', 'foo:bar'; end
    n = Blather::XMPPNode.new('foo')
    n.namespace = 'foo:bar'
    expect(Blather::XMPPNode.import(n)).to be_kind_of ImportSubClass
  end

  it 'can convert itself into a stanza' do
    class StanzaConvert < Blather::XMPPNode; register 'foo'; end
    n = Blather::XMPPNode.new('foo')
    expect(n.to_stanza).to be_kind_of StanzaConvert
  end

  it 'can parse a string and import it' do
    class StanzaParse < Blather::XMPPNode; register 'foo'; end
    string = '<foo/>'
    n = Nokogiri::XML(string).root
    i = Blather::XMPPNode.import n
    expect(i).to be_kind_of StanzaParse
    p = Blather::XMPPNode.parse string
    expect(p).to be_kind_of StanzaParse
  end
end
