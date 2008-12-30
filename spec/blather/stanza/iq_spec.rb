require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::Iq' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:iq, nil).must_equal Stanza::Iq
  end

  it 'creates a new Iq stanza defaulted as a get' do
    Stanza::Iq.new.type.must_equal :get
  end

  it 'wont import non-iq stanzas' do
    lambda { Stanza::Iq.import(XMPPNode.new('foo')) }.must_raise(Blather::ArgumentError)
  end

  it 'creates a new Stanza::Iq object on import' do
    Stanza::Iq.import(XMPPNode.new('iq')).must_be_kind_of Stanza::Iq
  end

  it 'creates a proper object based on its children' do
    n = XMPPNode.new('iq')
    n << XMPPNode.new('query')
    Stanza::Iq.import(n).must_be_kind_of Stanza::Iq::Query
  end
end
