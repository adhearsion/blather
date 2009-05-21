require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

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
end
