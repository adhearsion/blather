require 'spec_helper'

describe Blather::XMPPNode do
  before { @doc = Nokogiri::XML::Document.new }

  it 'generates a node based on the registered_name' do
    foo = Class.new(Blather::XMPPNode)
    foo.registered_name = 'foo'
    foo.new.element_name.should == 'foo'
  end

  it 'sets the namespace on creation' do
    foo = Class.new(Blather::XMPPNode)
    foo.registered_ns = 'foo'
    foo.new('foo').namespace.href.should == 'foo'
  end

  it 'registers sub classes' do
    class RegistersSubClass < Blather::XMPPNode; register 'foo', 'foo:bar'; end
    RegistersSubClass.registered_name.should == 'foo'
    RegistersSubClass.registered_ns.should == 'foo:bar'
    Blather::XMPPNode.class_from_registration('foo', 'foo:bar').should == RegistersSubClass
  end

  it 'imports another node' do
    class ImportSubClass < Blather::XMPPNode; register 'foo', 'foo:bar'; end
    n = Blather::XMPPNode.new('foo')
    n.namespace = 'foo:bar'
    Blather::XMPPNode.import(n).should be_kind_of ImportSubClass
  end

  it 'can convert itself into a stanza' do
    class StanzaConvert < Blather::XMPPNode; register 'foo'; end
    n = Blather::XMPPNode.new('foo')
    n.to_stanza.should be_kind_of StanzaConvert
  end

  it 'can parse a string and import it' do
    class StanzaParse < Blather::XMPPNode; register 'foo'; end
    string = '<foo/>'
    n = Nokogiri::XML(string).root
    i = Blather::XMPPNode.import n
    i.should be_kind_of StanzaParse
    p = Blather::XMPPNode.parse string
    p.should be_kind_of StanzaParse
  end
end
