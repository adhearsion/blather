require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'LibXML::XML::Node' do
  it 'aliases #name to #element_name' do
    node = LibXML::XML::Node.new 'foo'
    node.must_respond_to :element_name
    node.element_name.must_equal node.name
  end

  it 'aliases #name= to #element_name=' do
    node = LibXML::XML::Node.new 'foo'
    node.must_respond_to :element_name=
    node.element_name.must_equal node.name
    node.element_name = 'bar'
    node.element_name.must_equal 'bar'
  end
end

describe 'LibXML::XML::Attributes' do
  it 'provides a helper to remove a specified attribute' do
    attrs = LibXML::XML::Node.new('foo').attributes
    attrs['foo'] = 'bar'
    attrs['foo'].must_equal 'bar'
    attrs.remove 'foo'
    attrs['foo'].must_be_nil

    attrs['foo'] = 'bar'
    attrs['foo'].must_equal 'bar'
    attrs.remove :foo
    attrs['foo'].must_be_nil
  end

  it 'allows symbols as hash keys' do
    attrs = LibXML::XML::Node.new('foo').attributes
    attrs['foo'] = 'bar'

    attrs['foo'].must_equal 'bar'
    attrs[:foo].must_equal 'bar'
  end

  it 'removes an attribute when set to nil' do
    attrs = LibXML::XML::Node.new('foo').attributes
    attrs['foo'] = 'bar'

    attrs['foo'].must_equal 'bar'
    attrs['foo'] = nil
    attrs['foo'].must_be_nil
  end

  it 'allows attribute values to change' do
    attrs = LibXML::XML::Node.new('foo').attributes
    attrs['foo'] = 'bar'

    attrs['foo'].must_equal 'bar'
    attrs['foo'] = 'baz'
    attrs['foo'].must_equal 'baz'
  end
end
