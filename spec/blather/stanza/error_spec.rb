require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::Error' do
  it 'has can be constructed from another stanza' do
    Stanza::Error.must_respond_to :new_from
  end

  it 'turns a stanza into an error stanza' do
    iq = Stanza::Iq.new
    iq.type.wont_equal :error
    err = Stanza::Error.new_from(iq, 'service-unavailable', 'cancel')
    err.type.must_equal :error
  end

  it 'creates a node of the defined_condition in the proper namespace' do
    err = Stanza::Error.new_from(Stanza::Iq.new, 'service-unavailable', 'cancel')
    n = err.find_first('//service-unavailable', 'urn:ietf:params:xml:ns:xmpp-stanzas')
    n.wont_be_nil
    n.namespace.must_equal 'urn:ietf:params:xml:ns:xmpp-stanzas'
  end

  it 'add the proper type to the error node' do
    err = Stanza::Error.new_from(Stanza::Iq.new, 'service-unavailable', 'cancel')
    n = err.find_first('//service-unavailable', 'urn:ietf:params:xml:ns:xmpp-stanzas')
    n.wont_be_nil
    n.attributes[:type].must_equal 'cancel'
  end

  it 'adds a text node with optional text' do
    err = Stanza::Error.new_from(Stanza::Iq.new, 'service-unavailable', 'cancel', 'optional text')
    n = err.find_first('//text', 'urn:ietf:params:xml:ns:xmpp-stanzas')
    n.wont_be_nil
    n.namespace.must_equal 'urn:ietf:params:xml:ns:xmpp-stanzas'
    n.content.must_equal 'optional text'
  end

  it 'includes the original staza data' do
    query = Stanza::Iq::Query.new
    err = Stanza::Error.new_from(query, 'service-unavailable', 'cancel')
    err.element_name.must_equal query.element_name
    err.find_first('//query').wont_be_nil
  end

  it 'ensures type is one of Stanza::Error::VALID_TYPES' do
    lambda { Stanza::Error.new_from(Stanza::Iq.new, 'foo', :invalid_type_name) }.must_raise(Blather::ArgumentError)

    Stanza::Error::VALID_TYPES.each do |valid_type|
      msg = Stanza::Error.new_from(Stanza::Iq.new, 'foo', valid_type)
      msg.error_type.must_equal valid_type
    end
  end
end